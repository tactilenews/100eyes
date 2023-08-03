# frozen_string_literal: true

module WhatsAppAdapter
  UNKNOWN_CONTRIBUTOR = :unknown_contributor
  UNSUPPORTED_CONTENT = :unsupported_content
  REQUEST_FOR_MORE_INFO = :request_for_more_info
  REQUEST_TO_RECEIVE_MESSAGE = :request_to_receive_message
  UNSUBSCRIBE_CONTRIBUTOR = :unsubscribe_contributor
  SUBSCRIBE_CONTRIBUTOR = :subscribe_contributor

  class ThreeSixtyDialogInbound
    SUPPORTED_ATTACHMENT_TYPES = %w[image/jpg image/jpeg image/png image/gif audio/ogg video/mp4].freeze
    UNSUPPORTED_CONTENT_TYPES = %w[location contacts].freeze

    attr_reader :sender, :text, :message

    def initialize
      @callbacks = {}
    end

    def on(callback, &block)
      @callbacks[callback] = block
    end

    def consume(whats_app_message)
      whats_app_message = whats_app_message.with_indifferent_access

      @sender = initialize_sender(whats_app_message)
      return unless @sender

      @message = initialize_message(whats_app_message)
      return unless @message

      @unsupported_content = initialize_unsupported_content(whats_app_message)

      files = initialize_file(whats_app_message)
      @message.files = files

      return unless create_message?

      yield(@message) if block_given?
    end

    private

    def trigger(event, *args)
      return unless @callbacks.key?(event)

      @callbacks[event].call(*args)
    end

    def initialize_sender(whats_app_message)
      whats_app_phone_number = whats_app_message[:contacts].first[:wa_id].phony_normalized
      sender = Contributor.find_by(whats_app_phone_number: whats_app_phone_number)

      unless sender
        trigger(UNKNOWN_CONTRIBUTOR, whats_app_phone_number)
        return nil
      end

      sender
    end

    def initialize_message(whats_app_message)
      message = whats_app_message[:messages].first
      text = message[:text]&.dig(:body) || message[:button]&.dig(:text)

      trigger(REQUEST_FOR_MORE_INFO, sender) if request_for_more_info?(text)
      trigger(UNSUBSCRIBE_CONTRIBUTOR, sender) if unsubscribe_text?(text)
      trigger(SUBSCRIBE_CONTRIBUTOR, sender) if subscribe_text?(text)
      trigger(REQUEST_TO_RECEIVE_MESSAGE, sender) if request_to_receive_message?(sender, text)

      message = Message.new(text: text, sender: sender)
      message.raw_data.attach(
        io: StringIO.new(JSON.generate(whats_app_message)),
        filename: 'whats_app_message.json',
        content_type: 'application/json'
      )
      message
    end

    def initialize_unsupported_content(whats_app_message)
      return unless unsupported_content?(whats_app_message)

      message.unknown_content = true
      trigger(UNSUPPORTED_CONTENT, sender)
    end

    def initialize_file(whats_app_message)
      message = whats_app_message[:messages].first
      return [] unless message[:image] || message[:voice] || message[:video]

      file = Message::File.new

      message_file = message[:image] || message[:voice] || message[:video]
      content_type = message_file[:mime_type]
      file_id = message_file[:id]

      file.attachment.attach(
        io: StringIO.new(fetch_file(file_id)),
        filename: file_id,
        content_type: content_type,
        identify: false
      )

      [file]
    end

    def unsupported_content?(whats_app_message)
      message = whats_app_message[:messages].first
      return unless message

      errors = message[:errors]
      ((errors && errors.first[:title].match?(/Unsupported message type/)) || errors.first[:title].match?(/Received Wrong Message Type/)) ||
        message.keys.any? do |key|
          UNSUPPORTED_CONTENT_TYPES.include?(key)
        end
    end

    def request_for_more_info?(text)
      return false if text.blank?

      text.strip.eql?(I18n.t('adapter.whats_app.quick_reply_button_text.more_info'))
    end

    def request_to_receive_message?(contributor, text)
      return false if request_for_more_info?(text) || unsubscribe_text?(text) || subscribe_text?(text)

      contributor.whats_app_message_template_sent_at.present?
    end

    def quick_reply_response?(text)
      quick_reply_keys = %w[answer more_info]
      quick_reply_texts = []
      quick_reply_keys.each do |key|
        quick_reply_texts << I18n.t("adapter.whats_app.quick_reply_button_text.#{key}")
      end
      text.strip.in?(quick_reply_texts)
    end

    def unsubscribe_text?(text)
      return false if text.blank?

      text.downcase.strip.eql?(I18n.t('adapter.whats_app.unsubscribe.text'))
    end

    def subscribe_text?(text)
      return false if text.blank?

      text.downcase.strip.eql?(I18n.t('adapter.whats_app.subscribe.text'))
    end

    def create_message?
      has_non_text_content = message.files.any? || message.unknown_content
      text = message.text
      has_non_text_content || (message.text.present? && !quick_reply_response?(text) && !unsubscribe_text?(text) && !subscribe_text?(text))
    end

    def fetch_file(file_id)
      url = URI.parse("#{Setting.three_sixty_dialog_whats_app_rest_api_endpoint}/media/#{file_id}")
      headers = { 'D360-API-KEY' => Setting.three_sixty_dialog_api_key, 'Content-Type' => 'application/json' }
      request = Net::HTTP::Get.new(url.to_s, headers)
      response = Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
        http.request(request)
      end
      response.body
    end
  end
end

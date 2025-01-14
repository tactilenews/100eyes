# frozen_string_literal: true

module WhatsAppAdapter
  class ThreeSixtyDialogInbound
    UNKNOWN_CONTRIBUTOR = :unknown_contributor
    UNSUPPORTED_CONTENT = :unsupported_content
    REQUEST_FOR_MORE_INFO = :request_for_more_info
    REQUEST_TO_RECEIVE_MESSAGE = :request_to_receive_message
    UNSUBSCRIBE_CONTRIBUTOR = :unsubscribe_contributor
    RESUBSCRIBE_CONTRIBUTOR = :resubscribe_contributor
    UNSUPPORTED_CONTENT_TYPES = %w[location contacts application sticker].freeze

    attr_reader :sender, :text, :message, :organization, :whats_app_message

    def initialize
      @callbacks = {}
    end

    def on(callback, &block)
      @callbacks[callback] = block
    end

    def consume(organization, whats_app_message)
      @organization = organization
      @whats_app_message = whats_app_message

      @sender = initialize_sender
      return unless @sender

      @text = initialize_text

      if ephemeral_data?
        handle_ephemeral_data
        return
      end

      @message = initialize_message

      @unsupported_content = initialize_unsupported_content

      files = initialize_file
      @message.files = files

      yield(@message) if block_given?
    end

    private

    def trigger(event)
      return unless @callbacks.key?(event)

      @callbacks[event].call
    end

    def initialize_sender
      whats_app_phone_number = whats_app_message[:contacts].first[:wa_id].phony_normalized
      sender = organization.contributors.find_by(whats_app_phone_number: whats_app_phone_number)

      unless sender
        trigger(UNKNOWN_CONTRIBUTOR)
        return nil
      end

      sender
    end

    def initialize_text
      message = whats_app_message[:messages].first
      message[:text]&.dig(:body) || message[:button]&.dig(:text) || supported_file(message)&.dig(:caption)
    end

    def ephemeral_data?
      return if text.blank?

      request_for_more_info? || unsubscribe_text? || resubscribe_text? || request_to_receive_message?
    end

    def handle_ephemeral_data
      callback =
        if request_for_more_info?
          REQUEST_FOR_MORE_INFO
        elsif unsubscribe_text?
          UNSUBSCRIBE_CONTRIBUTOR
        elsif resubscribe_text?
          RESUBSCRIBE_CONTRIBUTOR
        elsif request_to_receive_message?
          REQUEST_TO_RECEIVE_MESSAGE
        end

      trigger(callback)
    end

    def initialize_message
      message = Message.new(text: text, sender: sender)
      message.raw_data.attach(
        io: StringIO.new(JSON.generate(text)),
        filename: 'whats_app_message.json',
        content_type: 'application/json'
      )
      message
    end

    def initialize_unsupported_content
      return unless unsupported_content?

      message.unknown_content = true
      trigger(UNSUPPORTED_CONTENT)
    end

    def initialize_file
      message = whats_app_message[:messages].first
      return [] unless file_type_supported?(message)

      file = Message::File.new

      message_file = supported_file(message)
      content_type = message_file[:mime_type]
      file_id = message_file[:id]
      filename = message_file[:filename] || file_id
      external_file = WhatsAppAdapter::ThreeSixtyDialog::FileFetcherService.call(organization_id: organization.id, file_id: file_id)

      file.attachment.attach(
        io: StringIO.new(external_file),
        filename: filename,
        content_type: content_type,
        identify: false
      )

      [file]
    end

    def file_type_supported?(message)
      supported_file = message[:image] || message[:voice] || message[:video] || message[:audio] ||
                       (message[:document] && UNSUPPORTED_CONTENT_TYPES.none? { |type| message[:document][:mime_type].include?(type) })
      supported_file.present?
    end

    def supported_file(message)
      message[:image] || message[:voice] || message[:video] || message[:audio] || message[:document]
    end

    def unsupported_content?
      message = whats_app_message[:messages].first
      return unless message

      unsupported_content = message.keys.any? do |key|
        UNSUPPORTED_CONTENT_TYPES.include?(key.to_s)
      end || UNSUPPORTED_CONTENT_TYPES.any? do |type|
        message[:document]&.dig(:mime_type) && message[:document][:mime_type].include?(type)
      end
      errors = message[:errors]
      return unsupported_content unless errors

      error_indicating_unsupported_content(errors)
    end

    def error_indicating_unsupported_content(errors)
      errors.first[:title].match?(/Unsupported message type/) || errors.first[:title].match?(/Received Wrong Message Type/)
    end

    def request_for_more_info?
      text.strip.eql?(organization.whats_app_quick_reply_button_text['more_info'])
    end

    def request_to_receive_message?
      answer_request_keyword = text.strip.eql?(organization.whats_app_quick_reply_button_text['answer_request'])
      sender.whats_app_message_template_sent_at.present? || answer_request_keyword
    end

    def quick_reply_response?
      text.strip.in?(organization.whats_app_quick_reply_button_text.values)
    end

    def unsubscribe_text?
      text.downcase.strip.eql?(I18n.t('adapter.shared.unsubscribe.text'))
    end

    def resubscribe_text?
      text.downcase.strip.eql?(I18n.t('adapter.shared.resubscribe.text'))
    end
  end
end

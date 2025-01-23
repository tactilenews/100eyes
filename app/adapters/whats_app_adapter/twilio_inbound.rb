# frozen_string_literal: true

module WhatsAppAdapter
  class TwilioInbound
    UNKNOWN_CONTRIBUTOR = :unknown_contributor
    UNSUPPORTED_CONTENT = :unsupported_content
    REQUEST_FOR_MORE_INFO = :request_for_more_info
    REQUEST_TO_RECEIVE_MESSAGE = :request_to_receive_message
    UNSUBSCRIBE_CONTRIBUTOR = :unsubscribe_contributor
    RESUBSCRIBE_CONTRIBUTOR = :resubscribe_contributor
    UNSUPPORTED_CONTENT_TYPES = %w[application text/vcard latitude longitude].freeze
    UNKNOWN_ORGANIZATION = :unknown_organization

    attr_reader :sender, :text, :message, :organization

    def initialize
      @callbacks = {}
    end

    def on(callback, &block)
      @callbacks[callback] = block
    end

    def consume(whats_app_message)
      whats_app_message = whats_app_message.with_indifferent_access

      @organization = initialize_organization(whats_app_message)
      return unless @organization

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

    def initialize_organization(whats_app_message)
      whats_app_server_phone_number = whats_app_message[:to].split('whatsapp:').last
      organization = Organization.find_by(whats_app_server_phone_number: whats_app_server_phone_number)

      unless organization
        trigger(UNKNOWN_ORGANIZATION, whats_app_server_phone_number)
        nil
      end

      organization
    end

    def initialize_sender(whats_app_message)
      whats_app_phone_number = whats_app_message[:wa_id].phony_normalized
      sender = organization.contributors.find_by(whats_app_phone_number: whats_app_phone_number)

      unless sender
        trigger(UNKNOWN_CONTRIBUTOR, whats_app_phone_number)
        return nil
      end

      sender
    end

    def initialize_message(whats_app_message)
      message_text = whats_app_message[:body]
      original_replied_message_sid = whats_app_message[:original_replied_message_sid]

      trigger(REQUEST_FOR_MORE_INFO, sender, organization) if request_for_more_info?(message_text)
      trigger(UNSUBSCRIBE_CONTRIBUTOR, sender, organization) if unsubscribe_text?(message_text)
      trigger(RESUBSCRIBE_CONTRIBUTOR, sender, organization) if resubscribe_text?(message_text)
      if request_to_receive_message?(sender, whats_app_message)
        trigger(REQUEST_TO_RECEIVE_MESSAGE, sender, original_replied_message_sid, organization)
      end
      message = Message.new(text: message_text, sender: sender, organization: organization)
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
      trigger(UNSUPPORTED_CONTENT, sender, organization)
    end

    def initialize_file(whats_app_message)
      return [] unless whats_app_message[:media_content_type0] && whats_app_message[:media_url0]

      file = Message::File.new

      content_type = whats_app_message[:media_content_type0]
      media_url = whats_app_message[:media_url0]
      filename = media_url.split('/Media/').last

      file.attachment.attach(
        io: URI.parse(media_url).open,
        filename: filename,
        content_type: content_type,
        identify: false
      )

      [file]
    end

    def unsupported_content?(whats_app_message)
      whats_app_message.keys.any? { |key| UNSUPPORTED_CONTENT_TYPES.include?(key) } || whats_app_message.any? do |key, value|
        key.match?(/media_content_type/) && UNSUPPORTED_CONTENT_TYPES.any? { |content_type| value.match?(/#{content_type}/) }
      end
    end

    def request_for_more_info?(text)
      text.strip.eql?(I18n.t('adapter.whats_app.quick_reply_button_text.more_info'))
    end

    def request_to_receive_message?(contributor, whats_app_message)
      text = whats_app_message[:body]
      return false if request_for_more_info?(text) || unsubscribe_text?(text) || resubscribe_text?(text)

      contributor.whats_app_message_template_sent_at.present? ||
        (whats_app_message[:original_replied_message_sid] &&
        whats_app_message[:button_text].eql?(I18n.t('adapter.whats_app.quick_reply_button_text.answer')))
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
      text&.downcase&.strip.eql?(I18n.t('adapter.shared.unsubscribe.text'))
    end

    def resubscribe_text?(text)
      text&.downcase&.strip.eql?(I18n.t('adapter.shared.resubscribe.text'))
    end

    def create_message?
      has_non_text_content = message.files.any? || message.unknown_content
      text = message.text
      has_non_text_content || (text.present? && !quick_reply_response?(text) && !unsubscribe_text?(text) && !resubscribe_text?(text))
    end
  end
end

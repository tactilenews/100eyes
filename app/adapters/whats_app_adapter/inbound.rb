# frozen_string_literal: true

module WhatsAppAdapter
  UNKNOWN_CONTRIBUTOR = :unknown_contributor
  UNSUPPORTED_CONTENT = :unsupported_content
  RESPONDING_TO_TEMPLATE_MESSAGE = :responding_to_template_message

  class Inbound
    SUPPORTED_ATTACHMENT_TYPES = %w[image/jpg image/jpeg image/png image/gif audio/ogg video/mp4].freeze
    UNSUPPORTED_CONTENT_TYPES = %w[application text/vcard latitude longitude].freeze

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

      has_content = @message.text || @message.files.any? || @message.unknown_content
      return unless has_content

      yield(@message) if block_given?
    end

    private

    def trigger(event, *args)
      return unless @callbacks.key?(event)

      @callbacks[event].call(*args)
    end

    def initialize_sender(whats_app_message)
      whats_app_phone_number = whats_app_message[:wa_id].phony_normalized
      sender = Contributor.find_by(whats_app_phone_number: whats_app_phone_number)

      unless sender
        trigger(UNKNOWN_CONTRIBUTOR, whats_app_phone_number)
        return nil
      end

      sender
    end

    def initialize_message(whats_app_message)
      trigger(RESPONDING_TO_TEMPLATE_MESSAGE, sender) if sender.whats_app_template_message_sent_at.present?

      message_text = whats_app_message[:body]
      message = Message.new(text: message_text, sender: sender)
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
  end
end

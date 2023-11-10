# frozen_string_literal: true

module ThreemaAdapter
  UNKNOWN_CONTRIBUTOR = :unknown_contributor
  UNSUBSCRIBE_CONTRIBUTOR = :unsubscribe_contributor
  SUBSCRIBE_CONTRIBUTOR = :subscribe_contributor
  UNSUPPORTED_CONTENT = :unsupported_content

  class Inbound
    UNSUPPORTED_CONTENT_TYPES = %w[application text/x-vcard].freeze
    attr_reader :sender, :unknown_content, :message

    def initialize
      @callbacks = {}
    end

    def on(callback, &block)
      @callbacks[callback] = block
    end

    def consume(threema_message)
      decrypted_message = Threema.new.receive(payload: threema_message)
      return if delivery_receipt?(decrypted_message)

      @sender = initialize_sender(threema_message)
      return unless @sender

      @message = initialize_message(decrypted_message)
      return unless @message

      @unsupported_content = initialize_unsupported_content(decrypted_message)

      files = initialize_files(decrypted_message)
      @message.files = files

      return unless create_message?

      yield(@message) if block_given?
    end

    def trigger(event, *args)
      return unless @callbacks.key?(event)

      @callbacks[event].call(*args)
    end

    private

    def delivery_receipt?(decrypted_message)
      decrypted_message.instance_of? Threema::Receive::DeliveryReceipt
    end

    def initialize_sender(threema_message)
      threema_id = threema_message[:from]
      sender = Contributor.where('UPPER(threema_id) = ?', threema_id).first

      unless sender
        trigger(UNKNOWN_CONTRIBUTOR, threema_id)
        return nil
      end

      sender
    end

    def initialize_message(decrypted_message)
      text = initialize_text(decrypted_message)

      trigger(UNSUBSCRIBE_CONTRIBUTOR, sender) if unsubscribe_text?(text)
      trigger(SUBSCRIBE_CONTRIBUTOR, sender) if subscribe_text?(text)
      message = Message.new(text: text, sender: sender)
      message.raw_data.attach(
        io: StringIO.new(decrypted_message.content),
        filename: 'threema_api.json',
        content_type: 'application/json'
      )
      message
    end

    def initialize_text(decrypted_message)
      return decrypted_message.caption if decrypted_message.instance_of?(Threema::Receive::File) && decrypted_message.caption

      decrypted_message.content
    end

    def initialize_unsupported_content(decrypted_message)
      return unless file_type_unsupported?(decrypted_message)

      message.unknown_content = true
      trigger(UNSUPPORTED_CONTENT, sender)
    end

    def initialize_files(decrypted_message)
      return [] unless decrypted_message.instance_of? Threema::Receive::File

      file = Message::File.new
      file.attachment.attach(
        io: StringIO.new(decrypted_message.content),
        filename: decrypted_message.name,
        content_type: decrypted_message.mime_type,
        identify: false,
        metadata: { caption: decrypted_message.caption }
      )
      [file]
    end

    def file_type_unsupported?(decrypted_message)
      return false unless decrypted_message.respond_to? :mime_type

      decrypted_message.instance_of?(Threema::Receive::NotImplementedFallback) ||
        UNSUPPORTED_CONTENT_TYPES.any? { |type| decrypted_message.mime_type.include? type }
    end

    def unsubscribe_text?(text)
      text&.downcase&.strip.eql?(I18n.t('adapter.shared.unsubscribe.text'))
    end

    def subscribe_text?(text)
      text&.downcase&.strip.eql?(I18n.t('adapter.shared.subscribe.text'))
    end

    def create_message?
      has_non_text_content = message.files.any? || message.unknown_content
      text = message.text
      has_non_text_content || (text.present? && !unsubscribe_text?(text) && !subscribe_text?(text))
    end
  end
end

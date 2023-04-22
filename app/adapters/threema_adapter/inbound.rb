# frozen_string_literal: true

module ThreemaAdapter
  UNKNOWN_CONTRIBUTOR = :unknown_contributor
  UNSUPPORTED_CONTENT = :unsupported_content
  DELIVERY_RECEIPT_RECEIVED = :delivery_receipt_received

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
      if delivery_receipt?(decrypted_message)
        trigger(DELIVERY_RECEIPT_RECEIVED)
        return
      end

      @sender = initialize_sender(threema_message)
      return unless @sender

      @message = initialize_message(decrypted_message)
      return unless @message

      @unsupported_content = initialize_unsupported_content(decrypted_message)

      files = initialize_files(decrypted_message)
      @message.files = files

      has_content = @message.text || @message.files.any? || @message.unknown_content
      return unless has_content

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
      message = Message.new(text: text, sender: sender)
      message.raw_data.attach(
        io: StringIO.new(decrypted_message.content),
        filename: 'threema_api.json',
        content_type: 'application/json'
      )
      message
    end

    def initialize_text(decrypted_message)
      if decrypted_message.instance_of? Threema::Receive::Text
        decrypted_message.content
      elsif decrypted_message.instance_of?(Threema::Receive::File) && decrypted_message.caption
        decrypted_message.caption
      end
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
  end
end

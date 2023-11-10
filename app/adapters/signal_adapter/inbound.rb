# frozen_string_literal: true

module SignalAdapter
  UNKNOWN_CONTRIBUTOR = :unknown_contributor
  UNKNOWN_CONTENT = :unknown_content
  CONNECT = :connect
  HANDLE_DELIVERY_RECEIPT = :handle_delivery_receipt

  class Inbound
    UNKNOWN_CONTENT_KEYS = %w[mentions contacts sticker].freeze
    SUPPORTED_ATTACHMENT_TYPES = %w[image/jpg image/jpeg image/png image/gif audio/oog audio/aac audio/mp4 audio/mpeg video/mp4].freeze

    attr_reader :sender, :text, :message

    def initialize
      @callbacks = {}
    end

    def on(callback, &block)
      @callbacks[callback] = block
    end

    def consume(signal_message)
      signal_message = signal_message.with_indifferent_access

      @sender = initialize_sender(signal_message)
      return unless @sender

      delivery_receipt = initialize_delivery_receipt(signal_message)
      return if delivery_receipt

      @message = initialize_message(signal_message)
      return unless @message

      files = initialize_files(signal_message)
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

    def initialize_sender(signal_message)
      signal_phone_number = signal_message.dig(:envelope, :source)
      sender = Contributor.find_by(signal_phone_number: signal_phone_number)
      return nil if signal_phone_number == Setting.signal_server_phone_number

      unless sender
        trigger(UNKNOWN_CONTRIBUTOR, signal_phone_number)
        return nil
      end

      if sender.signal_onboarding_completed_at.blank?
        trigger(CONNECT, sender)
        return nil
      end

      sender
    end

    def initialize_delivery_receipt(signal_message)
      delivery_receipt = signal_message.dig(:envelope, :receiptMessage)
      return nil unless delivery_receipt

      trigger(HANDLE_DELIVERY_RECEIPT, delivery_receipt, sender)
      delivery_receipt
    end

    def initialize_message(signal_message)
      is_data_message = signal_message.dig(:envelope, :dataMessage)
      is_remove_emoji = signal_message.dig(:envelope, :dataMessage, :reaction, :isRemove)

      return nil if !is_data_message || is_remove_emoji

      data_message = signal_message.dig(:envelope, :dataMessage)
      reaction = data_message[:reaction]

      message_text = reaction ? reaction[:emoji] : data_message[:message]

      message = Message.new(text: message_text, sender: sender)
      message.raw_data.attach(
        io: StringIO.new(JSON.generate(signal_message)),
        filename: 'signal_message.json',
        content_type: 'application/json'
      )

      if data_message.entries.any? { |key, value| UNKNOWN_CONTENT_KEYS.include?(key) && value.present? }
        message.unknown_content = true
        trigger(UNKNOWN_CONTENT, sender)
      end

      message
    end

    def initialize_files(signal_message)
      attachments = signal_message.dig(:envelope, :dataMessage, :attachments)
      return [] unless attachments&.any?

      if attachments.any? { |attachment| SUPPORTED_ATTACHMENT_TYPES.exclude?(attachment[:contentType]) }
        @message.unknown_content = true
        trigger(UNKNOWN_CONTENT, sender)
        attachments = attachments.select { |attachment| SUPPORTED_ATTACHMENT_TYPES.include?(attachment[:contentType]) }
      end

      attachments.map { |attachment| initialize_file(attachment) }
    end

    def initialize_file(attachment)
      file = Message::File.new

      # Some Signal clients do not set the filename
      content_type = attachment[:contentType]
      extension = Mime::Type.lookup(content_type).symbol.to_s
      filename = attachment[:filename] || "attachment.#{extension}"

      file.attachment.attach(
        io: File.open(Setting.signal_cli_rest_api_attachment_path + attachment[:id]),
        filename: filename,
        content_type: content_type,
        identify: false
      )

      file
    end
  end
end

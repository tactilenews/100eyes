# frozen_string_literal: true

module SignalAdapter
  UNKNOWN_CONTRIBUTOR = :unknown_contributor
  UNKNOWN_CONTENT = :unknown_content

  class Inbound
    UNKNOWN_CONTENT_KEYS = %w[mentions contacts reaction sticker].freeze
    SUPPORTED_ATTACHMENT_TYPES =  %w[image/jpg image/jpeg image/png image/gif audio/oog audio/aac audio/mp4].freeze

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

      @text = signal_message.dig(:envelope, :dataMessage, :message)
      @message = initialize_message(signal_message)
      return unless @message

      files = initialize_files(signal_message)
      @message.files = files

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
      return sender if sender

      trigger(UNKNOWN_CONTRIBUTOR, signal_phone_number) and return nil
    end

    def initialize_message(signal_message)
      is_receipt = signal_message.dig(:envelope, :receiptMessage)
      return nil if is_receipt

      data_message = signal_message.dig(:envelope, :dataMessage)

      message = Message.new(text: text, sender: sender)
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
      return [] unless attachments.any?

      if attachments.any? { |attachment| SUPPORTED_ATTACHMENT_TYPES.exclude?(attachment[:contentType]) }
        @message.unknown_content = true
        trigger(UNKNOWN_CONTENT, sender)
        attachments = attachments.select { |attachment| SUPPORTED_ATTACHMENT_TYPES.include?(attachment[:contentType]) }
      end 

      attachments.map {
        |attachment|
        file = Message::File.new
        file.attachment.attach(
          io: File.open('signal-cli-config/attachments/' +  attachment[:id]),
          filename: attachment[:filename],
          content_type: attachment[:contentType],
          identify: false
        )
        file
      }
    end 
  end
end

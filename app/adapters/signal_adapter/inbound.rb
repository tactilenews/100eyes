# frozen_string_literal: true

module SignalAdapter
  UNKNOWN_CONTRIBUTOR = :unknown_contributor
  UNKNOWN_CONTENT = :unknown_content

  class Inbound
    UNKNOWN_CONTENT_KEYS = %w[mentions attachments contacts].freeze

    attr_reader :sender, :text, :message

    def initialize
      @callbacks = {}
    end

    def on(callback, &block)
      @callbacks[callback] = block
    end

    def consume(signal_message)
      signal_message = signal_message.with_indifferent_access

      @text = signal_message.dig(:envelope, :dataMessage, :message)
      @sender = initialize_sender(signal_message)
      return unless @sender

      @message = initialize_message(signal_message)
      return unless @message

      yield(@message) if block_given?
    end

    private

    def trigger(event, *args)
      return unless @callbacks.key?(event)

      @callbacks[event].call(*args)
    end

    def initialize_sender(signal_message)
      phone_number = signal_message.dig(:envelope, :source)
      sender = Contributor.find_by(phone_number: phone_number)
      return sender if sender

      trigger(UNKNOWN_CONTRIBUTOR) and return nil
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
        trigger(UNKNOWN_CONTENT)
      end

      message
    end
  end
end

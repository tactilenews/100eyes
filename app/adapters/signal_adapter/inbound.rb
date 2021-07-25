# frozen_string_literal: true

module SignalAdapter
  class Inbound
    UNKNOWN_CONTRIBUTOR = :unknown_contributor
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

      message = Message.new(text: text, sender: sender)
      message.raw_data.attach(
        io: StringIO.new(JSON.generate(signal_message)),
        filename: 'signal_message.json',
        content_type: 'application/json'
      )
      message
    end
  end
end

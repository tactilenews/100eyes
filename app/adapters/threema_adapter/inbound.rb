# frozen_string_literal: true

module ThreemaAdapter
  class Inbound
    UNKNOWN_CONTENT_CLASS = [Threema::Receive::File, Threema::Receive::Image].freeze

    attr_reader :sender, :unknown_content, :message, :delivery_receipt

    def initialize(threema_message)
      decrypted_message = Threema.new.receive(payload: threema_message)

      @sender = Contributor.find_by(threema_id: threema_message[:from])
      return unless @sender

      @delivery_receipt = decrypted_message.instance_of? Threema::Receive::DeliveryReceipt
      @unknown_content = initialize_unknown_content(decrypted_message)
      @message = initialize_message(decrypted_message)
    end

    private

    def initialize_unknown_content(decrypted_message)
      @unknown_content = UNKNOWN_CONTENT_CLASS.any? { |klass| decrypted_message.instance_of? klass }
    end

    def initialize_message(decrypted_message)
      message = Message.new(text: decrypted_message.content, sender: sender)
      message.raw_data.attach(
        io: StringIO.new(decrypted_message.content),
        filename: 'threema_api.json',
        content_type: 'application/json'
      )
      message
    end
  end
end

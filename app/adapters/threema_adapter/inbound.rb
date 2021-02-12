# frozen_string_literal: true

module ThreemaAdapter
  class Inbound
    UNKNOWN_CONTENT_CLASS = [Threema::Receive::Image].freeze

    attr_reader :sender, :text, :unknown_content, :message, :delivery_receipt

    def initialize(threema_message)
      decrypted_message = Threema.new.receive(payload: threema_message)

      @sender = Contributor.find_by(threema_id: threema_message[:from])
      return unless @sender

      @delivery_receipt = delivery_receipt?(decrypted_message)
      @text = initialize_text(decrypted_message)
      @unknown_content = initialize_unknown_content(decrypted_message)
      @message = initialize_message(decrypted_message)
      @voice = initialize_voice(decrypted_message)
      @message.voice = @voice
    end

    private

    def delivery_receipt?(decrypted_message)
      decrypted_message.instance_of? Threema::Receive::DeliveryReceipt
    end

    def initialize_text(decrypted_message)
      return nil unless decrypted_message.instance_of? Threema::Receive::Text

      decrypted_message.content
    end

    def initialize_unknown_content(decrypted_message)
      @unknown_content = UNKNOWN_CONTENT_CLASS.any? { |klass| decrypted_message.instance_of? klass }
    end

    def initialize_message(decrypted_message)
      message = Message.new(text: text, sender: sender)
      message.raw_data.attach(
        io: StringIO.new(decrypted_message.content),
        filename: 'threema_api.json',
        content_type: 'application/json'
      )
      message.unknown_content = unknown_content
      message
    end

    def initialize_voice(decrypted_message)
      return nil unless decrypted_message.respond_to? :mime_type

      if decrypted_message.mime_type != 'audio/aac'
        message.unknown_content = true
        return
      end

      voice = Voice.new
      voice.attachment.attach(
        io: StringIO.new(decrypted_message.content),
        filename: decrypted_message.name,
        content_type: :audio,
        identify: false
      )
      voice
    end
  end
end

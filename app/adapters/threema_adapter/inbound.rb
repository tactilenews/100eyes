# frozen_string_literal: true

module ThreemaAdapter
  class Inbound
    UNSUPPORTED_CONTENT_TYPES = %w[video application text/x-vcard].freeze
    attr_reader :sender, :text, :unknown_content, :message, :delivery_receipt

    def self.bounce!(recipient:, text:)
      Threema.new.send(type: :text, threema_id: recipient.threema_id, text: text)
    end

    def initialize(threema_message)
      decrypted_message = Threema.new.receive(payload: threema_message)

      @sender = Contributor.find_by(threema_id: threema_message[:from])
      return unless @sender

      @delivery_receipt = delivery_receipt?(decrypted_message)
      @text = initialize_text(decrypted_message)
      @unknown_content = initialize_unknown_content(decrypted_message)
      @message = initialize_message(decrypted_message)
      @file = initialize_file(decrypted_message)
      @message.file = @file
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
      @unknown_content = decrypted_message.instance_of?(Threema::Receive::Image) || file_type_unsupported?(decrypted_message)
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

    def initialize_file(decrypted_message)
      return nil unless decrypted_message.instance_of? Threema::Receive::File

      file = Message::File.new
      file.attachment.attach(
        io: StringIO.new(decrypted_message.content),
        filename: decrypted_message.name,
        content_type: decrypted_message.mime_type,
        identify: false
      )
      message.unknown_content = unknown_content
      file
    end

    def file_type_unsupported?(decrypted_message)
      return false unless decrypted_message.respond_to? :mime_type

      UNSUPPORTED_CONTENT_TYPES.any? { |type| decrypted_message.mime_type.include? type }
    end
  end
end

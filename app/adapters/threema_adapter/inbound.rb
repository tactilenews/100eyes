# frozen_string_literal: true

module ThreemaAdapter
  UNKNOWN_ORGANIZATION = :unknown_organization
  UNKNOWN_CONTRIBUTOR = :unknown_contributor
  HANDLE_DELIVERY_RECEIPT = :handle_delivery_receipt
  UNSUBSCRIBE_CONTRIBUTOR = :unsubscribe_contributor
  RESUBSCRIBE_CONTRIBUTOR = :resubscribe_contributor
  UNSUPPORTED_CONTENT = :unsupported_content

  class Inbound
    UNSUPPORTED_CONTENT_TYPES = %w[application text/x-vcard].freeze
    attr_reader :sender, :unknown_content, :message, :organization

    def initialize
      @callbacks = {}
    end

    def on(callback, &block)
      @callbacks[callback] = block
    end

    def consume(threema_message)
      @organization = initialize_organization(threema_message[:to])
      return unless @organization

      threema = Threema.new(
        api_identity: @organization.threemarb_api_identity,
        api_secret: @organization.threemarb_api_secret,
        private_key: @organization.threemarb_private
      )
      # TODO: Handle organization that has not been configured
      decrypted_message = threema.receive(payload: threema_message)

      @sender = initialize_sender(threema_message)
      return unless @sender

      if delivery_receipt?(decrypted_message)
        trigger(HANDLE_DELIVERY_RECEIPT, decrypted_message, @organization)
        return
      end

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

    def initialize_organization(threemarb_api_identity)
      organization = Organization.find_by(threemarb_api_identity: threemarb_api_identity)

      unless organization
        trigger(UNKNOWN_ORGANIZATION, threemarb_api_identity)
        nil
      end

      organization
    end

    def initialize_sender(threema_message)
      threema_id = threema_message[:from]
      sender = organization.contributors.where('UPPER(threema_id) = ?', threema_id).first

      unless sender
        trigger(UNKNOWN_CONTRIBUTOR, threema_id)
        return nil
      end

      sender
    end

    def delivery_receipt?(decrypted_message)
      decrypted_message.instance_of? Threema::Receive::DeliveryReceipt
    end

    def initialize_text(decrypted_message)
      if decrypted_message.instance_of? Threema::Receive::Text
        decrypted_message.content
      elsif decrypted_message.instance_of?(Threema::Receive::File) && decrypted_message.caption
        decrypted_message.caption
      end
    end

    def initialize_message(decrypted_message)
      text = initialize_text(decrypted_message)

      trigger(UNSUBSCRIBE_CONTRIBUTOR, sender) if unsubscribe_text?(text)
      trigger(RESUBSCRIBE_CONTRIBUTOR, sender) if resubscribe_text?(text)
      message = Message.new(text: text, sender: sender, organization: organization)
      message.raw_data.attach(
        io: StringIO.new(decrypted_message.content),
        filename: 'threema_api.json',
        content_type: 'application/json'
      )
      message
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
      return true if decrypted_message.instance_of?(Threema::Receive::NotImplementedFallback)
      return false unless decrypted_message.respond_to?(:mime_type)

      UNSUPPORTED_CONTENT_TYPES.any? { |type| decrypted_message.mime_type.include? type }
    end

    def unsubscribe_text?(text)
      text&.downcase&.strip.eql?(I18n.t('adapter.shared.unsubscribe.text'))
    end

    def resubscribe_text?(text)
      text&.downcase&.strip.eql?(I18n.t('adapter.shared.resubscribe.text'))
    end

    def create_message?
      has_non_text_content = message.files.any? || message.unknown_content
      text = message.text
      has_non_text_content || (text.present? && !unsubscribe_text?(text) && !resubscribe_text?(text))
    end
  end
end

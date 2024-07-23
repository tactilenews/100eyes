# frozen_string_literal: true

module SignalAdapter
  UNKNOWN_CONTRIBUTOR = :unknown_contributor
  UNKNOWN_CONTENT = :unknown_content
  CONNECT = :connect
  UNSUBSCRIBE_CONTRIBUTOR = :unsubscribe_contributor
  RESUBSCRIBE_CONTRIBUTOR = :resubscribe_contributor
  HANDLE_DELIVERY_RECEIPT = :handle_delivery_receipt
  UNKNOWN_ORGANIZATION = :unknown_organization

  class Inbound
    UNKNOWN_CONTENT_KEYS = %w[mentions contacts sticker].freeze
    SUPPORTED_ATTACHMENT_TYPES = %w[image/jpg image/jpeg image/png image/gif audio/oog audio/aac audio/mp4 audio/mpeg video/mp4].freeze

    attr_reader :sender, :message, :organization

    def initialize
      @callbacks = {}
    end

    def on(callback, &block)
      @callbacks[callback] = block
    end

    def consume(signal_message)
      signal_message = signal_message.with_indifferent_access

      @organization = initialize_organization(signal_message)
      return unless organization

      @sender = initialize_contributing_sender(signal_message)

      delivery_receipt = initialize_delivery_receipt(signal_message)
      return if delivery_receipt

      unless @sender
        initialize_onboarding_sender(signal_message)
        return
      end

      remove_emoji = signal_message.dig(:envelope, :dataMessage, :reaction, :isRemove)
      return if remove_emoji

      @message = initialize_message(signal_message)
      return unless @message

      files = initialize_files(signal_message)
      @message.files = files

      return unless create_message?

      yield(@message) if block_given?
    end

    private

    def trigger(event, *args)
      return unless @callbacks.key?(event)

      @callbacks[event].call(*args)
    end

    def initialize_organization(signal_message)
      signal_server_phone_number = signal_message[:account]
      organization = Organization.find_by(signal_server_phone_number: signal_server_phone_number)

      unless organization
        trigger(UNKNOWN_ORGANIZATION, signal_server_phone_number)
        nil
      end

      organization
    end

    def initialize_contributing_sender(signal_message)
      signal_phone_number = signal_message.dig(:envelope, :sourceNumber)
      signal_uuid = signal_message.dig(:envelope, :sourceUuid)
      if signal_phone_number
        organization.contributors.find_by(signal_phone_number: signal_phone_number)
      else
        organization.contributors.find_by(signal_uuid: signal_uuid)
      end
    end

    def initialize_delivery_receipt(signal_message)
      return nil unless delivery_receipt?(signal_message) && sender

      delivery_receipt = signal_message.dig(:envelope, :receiptMessage)

      trigger(HANDLE_DELIVERY_RECEIPT, delivery_receipt, sender)
      delivery_receipt
    end

    def initialize_onboarding_sender(signal_message)
      signal_uuid = signal_message.dig(:envelope, :sourceUuid)
      signal_onboarding_token = signal_message.dig(:envelope, :dataMessage, :message)

      return nil unless signal_onboarding_token

      sender = organization.contributors.find_by(signal_onboarding_token: signal_onboarding_token.strip)

      unless sender
        trigger(UNKNOWN_CONTRIBUTOR, signal_message.dig(:envelope, :source))
        return nil
      end
      return unless signal_uuid

      trigger(CONNECT, sender, signal_uuid, organization)
    end

    # rubocop:disable Metrics/AbcSize
    def initialize_message(signal_message)
      is_data_message = signal_message.dig(:envelope, :dataMessage)
      return nil unless is_data_message

      data_message = signal_message.dig(:envelope, :dataMessage)
      reaction = data_message[:reaction]

      message_text = reaction ? reaction[:emoji] : data_message[:message]
      trigger(UNSUBSCRIBE_CONTRIBUTOR, sender, organization) if unsubscribe_text?(message_text)
      trigger(RESUBSCRIBE_CONTRIBUTOR, sender, organization) if resubscribe_text?(message_text)

      message = Message.new(text: message_text, sender: sender)
      message.raw_data.attach(
        io: StringIO.new(JSON.generate(signal_message)),
        filename: 'signal_message.json',
        content_type: 'application/json'
      )

      if data_message.entries.any? { |key, value| UNKNOWN_CONTENT_KEYS.include?(key) && value.present? }
        message.unknown_content = true
        trigger(UNKNOWN_CONTENT, sender, organization)
      end

      message
    end
    # rubocop:enable Metrics/AbcSize

    def initialize_files(signal_message)
      attachments = signal_message.dig(:envelope, :dataMessage, :attachments)
      return [] unless attachments&.any?

      if attachments.any? { |attachment| SUPPORTED_ATTACHMENT_TYPES.exclude?(attachment[:contentType]) }
        @message.unknown_content = true
        trigger(UNKNOWN_CONTENT, sender, organization)
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
        io: File.open(ENV.fetch('SIGNAL_CLI_REST_API_ATTACHMENT_PATH', 'signal-cli-config/attachments/') + attachment[:id]),
        filename: filename,
        content_type: content_type,
        identify: false
      )

      file
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

    def delivery_receipt?(signal_message)
      signal_message.dig(:envelope, :receiptMessage).present?
    end
  end
end

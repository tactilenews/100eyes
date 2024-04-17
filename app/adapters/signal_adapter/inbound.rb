# frozen_string_literal: true

module SignalAdapter
  UNKNOWN_CONTRIBUTOR = :unknown_contributor
  UNKNOWN_CONTENT = :unknown_content
  CONNECT = :connect
  UNSUBSCRIBE_CONTRIBUTOR = :unsubscribe_contributor
  RESUBSCRIBE_CONTRIBUTOR = :resubscribe_contributor
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

    def initialize_sender(signal_message)
      signal_phone_number = signal_message.dig(:envelope, :source)
      sender = Contributor.find_by(signal_phone_number: signal_phone_number)

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
      return nil unless is_data_message

      data_message = signal_message.dig(:envelope, :dataMessage)
      reaction = data_message[:reaction]

      message_text = reaction ? reaction[:emoji] : data_message[:message]
      trigger(UNSUBSCRIBE_CONTRIBUTOR, sender) if unsubscribe_text?(message_text)
      trigger(RESUBSCRIBE_CONTRIBUTOR, sender) if resubscribe_text?(message_text)

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

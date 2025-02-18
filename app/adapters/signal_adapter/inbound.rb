# frozen_string_literal: true

module SignalAdapter
  class Inbound
    UNKNOWN_CONTENT_KEYS = %i[mentions contacts sticker].freeze
    SUPPORTED_ATTACHMENT_TYPES = %w[image/jpg image/jpeg image/png image/gif audio/oog audio/aac audio/mp4 audio/mpeg video/mp4].freeze

    attr_reader :signal_message, :contributor, :data_message, :text, :quote_reply_message_id, :message

    def initialize; end

    def consume(contributor, signal_message)
      @signal_message = signal_message
      @contributor = contributor

      @data_message = signal_message.dig(:envelope, :dataMessage)
      return unless data_message

      @text = initialize_text
      return if ephemeral_data_handled?

      @quote_reply_message_id = data_message.dig(:quote, :id)
      @message = initialize_message
      return unless message

      @unsupported_content = initialize_unsupported_content

      files = initialize_files
      message.files = files
      message.request = attach_request

      has_content = message.text || message.files.any? || message.unknown_content
      return unless has_content

      message.save!
      message
    end

    private

    def initialize_text
      data_message.dig(:reaction, :emoji) || data_message[:message]
    end

    def ephemeral_data_handled?
      return true if data_message.dig(:reaction, :isRemove)
      return false if text.blank?

      if unsubscribe_text?
        handle_unsubscribe
      elsif resubscribe_text?
        handle_resubscribe
      else
        return false
      end
      true
    end

    def initialize_message
      timestamp = signal_message.dig(:envelope, :timestamp)

      message = Message.new(
        text: text,
        sender: contributor,
        organization: contributor.organization,
        external_id: timestamp.to_s,
        reply_to_external_id: quote_reply_message_id,
        created_at: Time.zone.at(timestamp / 1000).to_datetime
      )
      message.raw_data.attach(
        io: StringIO.new(JSON.generate(signal_message)),
        filename: 'signal_message.json',
        content_type: 'application/json'
      )

      message
    end

    def initialize_unsupported_content
      return unless data_message.entries.any? do |key, value|
                      UNKNOWN_CONTENT_KEYS.include?(key) && value.present?
                    end

      handle_unsupported_content
    end

    def initialize_files
      attachments = data_message[:attachments]
      return [] unless attachments&.any?

      if attachments.any? { |attachment| SUPPORTED_ATTACHMENT_TYPES.exclude?(attachment[:contentType]) }
        handle_unsupported_content
        attachments = attachments.select { |attachment| SUPPORTED_ATTACHMENT_TYPES.include?(attachment[:contentType]) }
      end

      attachments.map { |attachment| initialize_file(attachment) }
    end

    def handle_unsupported_content
      message.unknown_content = true
      SignalAdapter::Outbound.send_unsupported_content_message!(contributor)
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

    def attach_request
      message = Message.find_by(external_id: quote_reply_message_id) if quote_reply_message_id
      message&.request || contributor.received_messages.first&.request
    end

    def unsubscribe_text?
      text&.downcase&.strip.eql?(I18n.t('adapter.shared.unsubscribe.text'))
    end

    def resubscribe_text?
      text&.downcase&.strip.eql?(I18n.t('adapter.shared.resubscribe.text'))
    end

    def handle_unsubscribe
      UnsubscribeContributorJob.perform_later(contributor.id, SignalAdapter::Outbound)
    end

    def handle_resubscribe
      ResubscribeContributorJob.perform_later(contributor.id, SignalAdapter::Outbound)
    end
  end
end

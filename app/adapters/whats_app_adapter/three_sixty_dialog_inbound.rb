# frozen_string_literal: true

module WhatsAppAdapter
  class ThreeSixtyDialogInbound
    UNSUPPORTED_CONTENT_TYPES = %w[location contacts application sticker].freeze

    attr_reader :sender, :text, :message, :organization, :whats_app_message

    def initialize; end

    def consume(organization, whats_app_message)
      @organization = organization
      @whats_app_message = whats_app_message

      @sender = initialize_sender
      return unless @sender

      @text = initialize_text

      if ephemeral_data?
        handle_ephemeral_data
        return
      end

      @message = initialize_message

      @unsupported_content = initialize_unsupported_content

      files = initialize_file
      @message.files = files

      yield(@message) if block_given?
    end

    private

    def initialize_sender
      whats_app_phone_number = whats_app_message[:contacts].first[:wa_id].phony_normalized
      sender = organization.contributors.find_by(whats_app_phone_number: whats_app_phone_number)

      unless sender
        exception = WhatsAppAdapter::UnknownContributorError.new(whats_app_phone_number: whats_app_phone_number)
        ErrorNotifier.report(exception)
        return nil
      end

      sender
    end

    def initialize_text
      message = whats_app_message[:messages].first
      message[:text]&.dig(:body) || message[:button]&.dig(:text)
    end

    def ephemeral_data?
      return if text.blank?

      request_for_more_info? || unsubscribe_text? || resubscribe_text? || request_to_receive_message?
    end

    def handle_ephemeral_data
      type =
        if request_for_more_info?
          :request_for_more_info
        elsif unsubscribe_text?
          :unsubscribe
        elsif resubscribe_text?
          :resubscribe
        elsif request_to_receive_message?
          external_message_id = whats_app_message[:messages].first.dig(:context, :id)
          :request_to_receive_message
        end
      WhatsAppAdapter::ThreeSixtyDialog::HandleEphemeralDataJob.perform_later(
        type: type,
        contributor_id: sender.id,
        external_message_id: external_message_id
      )
    end

    def initialize_message
      message = Message.new(text: text, sender: sender)
      message.raw_data.attach(
        io: StringIO.new(JSON.generate(whats_app_message)),
        filename: 'whats_app_message.json',
        content_type: 'application/json'
      )
      message
    end

    def initialize_unsupported_content
      return unless unsupported_content?

      message.unknown_content = true
      WhatsAppAdapter::ThreeSixtyDialogOutbound.send_unsupported_content_message!(sender)
    end

    def initialize_file
      message_payload = whats_app_message[:messages].first
      return [] unless file_type_supported?(message_payload)

      file = Message::File.new

      message_file = supported_file(message_payload)
      caption = message_file[:caption]
      content_type = message_file[:mime_type]
      file_id = message_file[:id]
      filename = message_file[:filename] || file_id
      external_file = WhatsAppAdapter::ThreeSixtyDialog::FileFetcherService.call(organization_id: organization.id, file_id: file_id)

      file.attachment.attach(
        io: StringIO.new(external_file),
        filename: filename,
        content_type: content_type,
        identify: false
      )

      message.text = caption if caption

      [file]
    end

    def file_type_supported?(message)
      supported_file = message[:image] || message[:voice] || message[:video] || message[:audio] ||
                       (message[:document] && UNSUPPORTED_CONTENT_TYPES.none? { |type| message[:document][:mime_type].include?(type) })
      supported_file.present?
    end

    def supported_file(message)
      message[:image] || message[:voice] || message[:video] || message[:audio] || message[:document]
    end

    def unsupported_content?
      message = whats_app_message[:messages].first
      return unless message

      unsupported_content = message.keys.any? do |key|
        UNSUPPORTED_CONTENT_TYPES.include?(key.to_s)
      end || UNSUPPORTED_CONTENT_TYPES.any? do |type|
        message[:document]&.dig(:mime_type) && message[:document][:mime_type].include?(type)
      end
      errors = message[:errors]
      return unsupported_content unless errors

      error_indicating_unsupported_content(errors)
    end

    def error_indicating_unsupported_content(errors)
      errors.first[:title].match?(/Unsupported message type/) || errors.first[:title].match?(/Received Wrong Message Type/)
    end

    def request_for_more_info?
      text.strip.eql?(organization.whats_app_quick_reply_button_text['more_info'])
    end

    def request_to_receive_message?
      answer_request_keyword = text.strip.eql?(organization.whats_app_quick_reply_button_text['answer_request'])
      sender.whats_app_message_template_sent_at.present? || answer_request_keyword
    end

    def unsubscribe_text?
      text.downcase.strip.eql?(I18n.t('adapter.shared.unsubscribe.text'))
    end

    def resubscribe_text?
      text.downcase.strip.eql?(I18n.t('adapter.shared.resubscribe.text'))
    end
  end
end

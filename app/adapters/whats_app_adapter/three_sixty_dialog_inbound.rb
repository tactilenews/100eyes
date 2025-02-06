# frozen_string_literal: true

module WhatsAppAdapter
  class ThreeSixtyDialogInbound
    UNSUPPORTED_CONTENT_TYPES = %w[location contacts application sticker].freeze

    attr_reader :sender, :text, :message, :organization, :whats_app_payload, :message_payload, :quote_reply_message_id

    def initialize; end

    def consume(organization, whats_app_payload)
      @organization = organization
      @whats_app_payload = whats_app_payload

      @sender = initialize_sender
      return unless @sender

      @message_payload = whats_app_payload[:messages].first
      @quote_reply_message_id = message_payload.dig(:context, :id)
      @text = initialize_text

      return if ephemeral_data_handled?

      @message = initialize_message

      @unsupported_content = initialize_unsupported_content

      files = initialize_file
      @message.files = files
      @message.request = sender.received_messages.first&.request

      @message.save!
      @message
    end

    private

    def initialize_sender
      whats_app_phone_number = whats_app_payload[:contacts].first[:wa_id].phony_normalized
      sender = organization.contributors.find_by(whats_app_phone_number: whats_app_phone_number)

      unless sender
        exception = WhatsAppAdapter::UnknownContributorError.new(whats_app_phone_number: whats_app_phone_number)
        ErrorNotifier.report(exception)
        return nil
      end

      sender
    end

    def initialize_text
      message_payload[:text]&.dig(:body) || message_payload[:button]&.dig(:text)
    end

    def ephemeral_data_handled?
      return false if text.blank?

      if request_for_more_info?
        handle_request_for_more_info
      elsif unsubscribe_text?
        handle_unsubscribe
      elsif resubscribe_text?
        handle_resubscribe
      elsif request_to_receive_message? || requested_message
        handle_request_to_receive_message
      else
        return false
      end
      true
    end

    def initialize_message
      message = Message.new(text: text, sender: sender, external_id: message_payload[:id], organization: organization)
      message.raw_data.attach(
        io: StringIO.new(JSON.generate(whats_app_payload)),
        filename: 'whats_app_payload.json',
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
      return unless message_payload

      unsupported_content = message_payload.keys.any? do |key|
        UNSUPPORTED_CONTENT_TYPES.include?(key.to_s)
      end || UNSUPPORTED_CONTENT_TYPES.any? do |type|
        message_payload[:document]&.dig(:mime_type) && message_payload[:document][:mime_type].include?(type)
      end
      errors = message_payload[:errors]
      return unsupported_content unless errors

      error_indicating_unsupported_content(errors)
    end

    def error_indicating_unsupported_content(errors)
      errors.first[:title].match?(/Unsupported message type/) || errors.first[:title].match?(/Received Wrong Message Type/)
    end

    def request_for_more_info?
      text.strip.eql?(organization.whats_app_quick_reply_button_text['more_info'])
    end

    # TODO: Remove this after we have some time actually saving Message::WhatsAppTemplate records
    def request_to_receive_message?
      text.downcase.strip.eql?(organization.whats_app_quick_reply_button_text['answer_request'].downcase)
    end

    def requested_message
      Message::WhatsAppTemplate.find_by(external_id: quote_reply_message_id)&.message
    end

    def unsubscribe_text?
      text.downcase.strip.eql?(I18n.t('adapter.shared.unsubscribe.text'))
    end

    def resubscribe_text?
      text.downcase.strip.eql?(I18n.t('adapter.shared.resubscribe.text'))
    end

    def handle_request_for_more_info
      sender.update!(whats_app_message_template_responded_at: Time.current)
      WhatsAppAdapter::ThreeSixtyDialogOutbound.send_more_info_message!(sender)
    end

    def handle_unsubscribe
      UnsubscribeContributorJob.perform_later(organization.id, sender.id, WhatsAppAdapter::ThreeSixtyDialogOutbound)
    end

    def handle_resubscribe
      ResubscribeContributorJob.perform_later(organization.id, sender.id, WhatsAppAdapter::ThreeSixtyDialogOutbound)
    end

    def handle_request_to_receive_message
      sender.update!(whats_app_message_template_responded_at: Time.current)
      WhatsAppAdapter::ThreeSixtyDialogOutbound.send!(requested_message || sender.received_messages.first)
    end
  end
end

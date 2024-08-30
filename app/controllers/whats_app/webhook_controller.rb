# frozen_string_literal: true

# TODO: Reduce ClassLength, extract status and error to own classes(?)
# rubocop:disable Metrics/ClassLength
module WhatsApp
  class WebhookController < ApplicationController
    include WhatsAppHandleCallbacks

    skip_before_action :require_login, :verify_authenticity_token, :user_permitted?
    before_action :set_organization, only: :status
    before_action :set_contributor, only: :status

    UNSUCCESSFUL_DELIVERY = %w[undelivered failed].freeze
    SUCCESSFUL_DELIVERY = %w[delivered read].freeze
    INVALID_MESSAGE_RECIPIENT_ERROR_CODE = 63_024 # https://www.twilio.com/docs/api/errors/63024
    FREEFORM_MESSAGE_NOT_ALLOWED_ERROR_CODE = 63_016 # https://www.twilio.com/docs/api/errors/63016
    attr_reader :adapter

    def message
      head :ok
      @adapter = WhatsAppAdapter::TwilioInbound.new

      handle_callbacks

      whats_app_message_params = message_params.to_h.transform_keys(&:underscore)
      adapter.consume(whats_app_message_params) { |message| message.contributor.reply(adapter) }
    end

    def errors
      head :ok
      return unless error_params['Level'] == 'ERROR'

      payload = JSON.parse(error_params['Payload']).deep_transform_keys(&:underscore).with_indifferent_access
      parameters = payload.dig(:webhook, :request, :parameters)
      more_info = payload[:more_info]
      message = more_info&.dig(:msg)
      url = more_info&.dig(:url)
      exception = WhatsAppAdapter::TwilioError.new(error_code: payload['error_code'], message: message, url: url)
      ErrorNotifier.report(exception,
                           context: {
                             channel_to_address: parameters&.dig(:channelToAddress),
                             more_info: more_info,
                             error_sid: error_params['Sid'],
                             message_sid: parameters&.dig(:message_sid)
                           })
    end

    def status
      head :ok
      handle_unsuccessful_delivery if status_params['MessageStatus'].in?(UNSUCCESSFUL_DELIVERY)
      handle_successful_delivery if status_params['MessageStatus'].in?(SUCCESSFUL_DELIVERY)
    end

    private

    def message_params
      params.permit(:AccountSid, :ApiVersion, :Body, :ButtonText, :ButtonPayload, :From, :Latitude, :Longitude,
                    :MediaContentType0, :MediaUrl0, :MessageSid, :MessageType, :NumMedia, :NumSegments,
                    :OriginalRepliedMessageSender, :OriginalRepliedMessageSid, :ProfileName,
                    :ReferralNumMedia, :SmsMessageSid, :SmsSid, :SmsStatus, :To, :WaId)
    end

    def error_params
      params.permit(:AccountSid, :Level, :ParentAccountSid, :Payload, :PayloadType, :Sid, :Timestamp)
    end

    def status_params
      params.permit(:AccountSid, :ApiVersion, :ChannelInstallSid, :ChannelPrefix, :ChannelToAddress, :ErrorCode, :ErrorMessage,
                    :EventType, :From, :MessageSid, :MessageStatus, :SmsSid, :SmsStatus, :StructuredMessage, :To)
    end

    def set_organization
      whats_app_server_phone_number = status_params['From'].split('whatsapp:').last
      @organization = Organization.find_by(whats_app_server_phone_number: whats_app_server_phone_number)
      handle_unknown_organization(whats_app_server_phone_number) unless @organization
      @organization
    end

    def set_contributor
      return unless @organization

      whats_app_phone_number = status_params['To'].split('whatsapp:').last
      @contributor = @organization.contributors.find_by(whats_app_phone_number: whats_app_phone_number)
    end

    def handle_callbacks
      adapter.on(WhatsAppAdapter::TwilioInbound::UNKNOWN_ORGANIZATION) do |whats_app_server_phone_number|
        handle_unknown_organization(whats_app_server_phone_number)
      end

      adapter.on(WhatsAppAdapter::TwilioInbound::UNKNOWN_CONTRIBUTOR) do |whats_app_phone_number|
        handle_unknown_contributor(whats_app_phone_number)
      end

      adapter.on(WhatsAppAdapter::TwilioInbound::REQUEST_FOR_MORE_INFO) do |contributor, organization|
        handle_request_for_more_info(contributor, organization)
      end

      adapter.on(WhatsAppAdapter::TwilioInbound::REQUEST_TO_RECEIVE_MESSAGE) do |contributor, twilio_message_sid, organization|
        handle_request_to_receive_message(contributor, twilio_message_sid, organization)
      end

      adapter.on(WhatsAppAdapter::TwilioInbound::UNSUPPORTED_CONTENT) do |contributor, organization|
        WhatsAppAdapter::TwilioOutbound.send_unsupported_content_message!(contributor, organization)
      end

      adapter.on(WhatsAppAdapter::TwilioInbound::UNSUBSCRIBE_CONTRIBUTOR) do |contributor, organization|
        UnsubscribeContributorJob.perform_later(organization.id, contributor.id, WhatsAppAdapter::TwilioOutbound)
      end

      adapter.on(WhatsAppAdapter::TwilioInbound::RESUBSCRIBE_CONTRIBUTOR) do |contributor, organization|
        ResubscribeContributorJob.perform_later(organization.id, contributor.id, WhatsAppAdapter::TwilioOutbound)
      end
    end

    def handle_unknown_organization(whats_app_server_phone_number)
      exception = WhatsAppAdapter::UnknownOrganizationError.new(whats_app_server_phone_number: whats_app_server_phone_number)
      ErrorNotifier.report(exception)
    end

    def handle_unknown_contributor(whats_app_phone_number)
      exception = WhatsAppAdapter::UnknownContributorError.new(whats_app_phone_number: whats_app_phone_number)
      ErrorNotifier.report(exception)
    end

    def handle_request_to_receive_message(contributor, twilio_message_sid, organization)
      contributor.update!(whats_app_message_template_responded_at: Time.current, whats_app_message_template_sent_at: nil)

      message = (send_requested_message(contributor, twilio_message_sid, organization) if twilio_message_sid)
      WhatsAppAdapter::TwilioOutbound.send!(message || contributor.received_messages.first)
    end

    def send_requested_message(contributor, twilio_message_sid, organization)
      message_text = fetch_message_from_twilio(twilio_message_sid, organization)

      request_title = message_text.scan(/„[^"]*“/).first&.gsub('„', '')&.gsub('“', '')
      request = organization.requests.find_by(title: request_title)

      request&.messages&.where(recipient_id: contributor.id)&.first
    end

    def fetch_message_from_twilio(twilio_message_sid, organization)
      message = organization.twilio_instance.messages(twilio_message_sid).fetch
      message.body
    rescue Twilio::REST::RestError => e
      ErrorNotifier.report(e)
      nil
    end

    def handle_freeform_message_not_allowed_error(contributor, twilio_message_sid)
      message_text = fetch_message_from_twilio(twilio_message_sid, @organization)
      message = @organization.messages.find_by(text: message_text)
      return unless message

      WhatsAppAdapter::TwilioOutbound.send_message_template!(contributor, message)
    end

    def handle_unsuccessful_delivery
      return unless @contributor

      if status_params['ErrorCode'].to_i.eql?(INVALID_MESSAGE_RECIPIENT_ERROR_CODE)
        MarkInactiveContributorInactiveJob.perform_later(organization_id: @organization.id, contributor_id: @contributor.id)
        return
      end
      if status_params['ErrorCode'].to_i.eql?(FREEFORM_MESSAGE_NOT_ALLOWED_ERROR_CODE) && status_params['MessageStatus'].eql?('failed')
        handle_freeform_message_not_allowed_error(@contributor, status_params['MessageSid'])
      end
      exception = WhatsAppAdapter::MessageDeliveryUnsuccessfulError.new(status: status_params['MessageStatus'],
                                                                        whats_app_phone_number: @contributor.whats_app_phone_number,
                                                                        message: status_params['ErrorMessage'])
      ErrorNotifier.report(exception, context: { message_sid: status_params['MessageSid'] })
    end

    def handle_successful_delivery
      return unless @contributor

      message = @organization.messages.where(external_id: status_params['MessageSid']).first
      return unless message

      delivered_status = SUCCESSFUL_DELIVERY.first
      read_status = SUCCESSFUL_DELIVERY.last
      message.update(received_at: Time.current) if status_params['MessageStatus'].eql?(delivered_status)

      return unless status_params['MessageStatus'].eql?(read_status)

      message.received_at = Time.current if message.received_at.blank?
      message.update(read_at: Time.current)
    end

    def handle_request_for_more_info(contributor, organization)
      contributor.update!(whats_app_message_template_responded_at: Time.current)

      WhatsAppAdapter::TwilioOutbound.send_more_info_message!(contributor, organization)
    end
  end
end
# rubocop:enable Metrics/ClassLength

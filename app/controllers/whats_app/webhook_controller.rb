# frozen_string_literal: true

module WhatsApp
  class WebhookController < ApplicationController
    skip_before_action :require_login, :verify_authenticity_token
    UNSUCCESSFUL_DELIVERY = %w[undelivered failed].freeze

    def message
      adapter = WhatsAppAdapter::Inbound.new

      adapter.on(WhatsAppAdapter::UNKNOWN_CONTRIBUTOR) do |whats_app_phone_number|
        exception = WhatsAppAdapter::UnknownContributorError.new(whats_app_phone_number: whats_app_phone_number)
        ErrorNotifier.report(exception)
      end

      adapter.on(WhatsAppAdapter::RESPONDING_TO_TEMPLATE_MESSAGE) do |contributor|
        contributor.update!(whats_app_message_template_responded_at: Time.current, whats_app_template_message_sent_at: nil)
        message = contributor.received_messages.first
        WhatsAppAdapter::Outbound.send!(message)
      end

      adapter.on(WhatsAppAdapter::UNKNOWN_CONTENT) do |contributor|
        WhatsAppAdapter::Outbound.send_unknown_content_message!(contributor)
      end

      whats_app_webhook_params = webhook_params.to_h.transform_keys(&:underscore)
      adapter.consume(whats_app_webhook_params) { |message| message.contributor.reply(adapter) }
    end

    def errors
      return unless webhook_params['Level'] == 'ERROR'

      payload = JSON.parse(webhook_params['Payload'])
      parameters = payload.with_indifferent_access.dig(:webhook, :request, :parameters)
      exception = WhatsAppAdapter::TwilioError.new(error_code: payload['error_code'])
      ErrorNotifier.report(exception,
                           context: {
                             channel_to_address: parameters&.dig(:channelToAddress),
                             more_info: payload['more_info'],
                             error_sid: webhook_params['Sid'],
                             message_sid: parameters&.dig(:messageSid)
                           })
    end

    def status
      return unless status_params['MessageStatus'].in?(UNSUCCESSFUL_DELIVERY)

      exception = WhatsAppAdapter::MessageDeliveryUnsuccessfulError.new(status: status_params['MessageStatus'],
                                                                        whats_app_phone_number: status_params['To'].split('whatsapp:').last)
      ErrorNotifier.report(exception, context: { message_sid: status_params['MessageSid'] })
    end

    private

    def webhook_params
      params.permit(:AccountSid, :ApiVersion, :Body, :ButtonText, :ButtonPayload, :From, :Level, :Latitude, :Longitude,
                    :MediaContentType0, :MediaUrl0, :MessageSid, :NumMedia, :NumSegments, :ParentAccountSid, :Payload,
                    :PayloadType, :ProfileName, :ReferralNumMedia, :Sid, :SmsMessageSid, :SmsSid, :SmsStatus, :Timestamp,
                    :To, :WaId)
    end

    def status_params
      params.permit(:AccountSid, :ApiVersion, :ChannelInstallSid, :ChannelPrefix, :ChannelToAddress, :ErrorCode, :EventType,
                    :From, :MessageSid, :MessageStatus, :SmsSid, :SmsStatus, :To)
    end
  end
end

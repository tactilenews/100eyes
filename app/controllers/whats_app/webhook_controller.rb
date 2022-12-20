# frozen_string_literal: true

module WhatsApp
  class WebhookController < ApplicationController
    skip_before_action :require_login, :verify_authenticity_token

    def message
      adapter = WhatsAppAdapter::Inbound.new

      adapter.on(WhatsAppAdapter::CONNECT) do |contributor|
        contributor.update!(whats_app_onboarding_completed_at: Time.zone.now)
        WhatsAppAdapter::Outbound.send_welcome_message!(contributor)
      end

      adapter.on(WhatsAppAdapter::UNKNOWN_CONTRIBUTOR) do |signal_phone_number|
        exception = WhatsAppAdapter::UnknownContributorError.new(signal_phone_number: signal_phone_number)
        ErrorNotifier.report(exception)
      end

      adapter.on(WhatsAppAdapter::RESPONDING_TO_TEMPLATE_MESSAGE) do |contributor|
        contributor.update!(latest_message_received_at: Time.current, whats_app_template_message_sent_at: nil)
        message = contributor.received_messages.first
        WhatsAppAdapter::Outbound.send!(message)
      end

      whats_app_webhook_params = webhook_params.to_h.transform_keys(&:underscore)
      adapter.consume(whats_app_webhook_params)
    end

    private

    def webhook_params
      params.permit(:WaId, :SmsMessageSid, :NumMedia, :ProfileName, :SmsSid, :SmsStatus, :Body, :To, :NumSegments, :ReferralNumMedia,
                    :MessageSid, :AccountSid, :From, :ApiVersion)
    end
  end
end

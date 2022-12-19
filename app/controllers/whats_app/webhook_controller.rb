# frozen_string_literal: true

module WhatsApp
  class WebhookController < ApplicationController
    skip_before_action :require_login, :verify_authenticity_token

    def message
      adapter = WhatsAppAdapter::Inbound.new
      contributor_connected = false

      adapter.on(WhatsAppAdapter::UNKNOWN_CONTRIBUTOR) do |signal_phone_number|
        exception = WhatsAppAdapter::UnknownContributorError.new(signal_phone_number: signal_phone_number)
        ErrorNotifier.report(exception)
      end

      whats_app_webhook_params = webhook_params.to_h.transform_keys(&:underscore)
      adapter.consume(whats_app_webhook_params) do |message|
        unless contributor_connected
          message.contributor.save!
          message.contributor.reply(adapter)
        end
      end
    end

    private

    def webhook_params
      params.permit(:WaId, :SmsMessageSid, :NumMedia, :ProfileName, :SmsSid, :SmsStatus, :Body, :To, :NumSegments, :ReferralNumMedia,
                    :MessageSid, :AccountSid, :From, :ApiVersion)
    end
  end
end

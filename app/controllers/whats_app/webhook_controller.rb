# frozen_string_literal: true

module WhatsApp
  class WebhookController < ApplicationController
    skip_before_action :require_login, :verify_authenticity_token
    before_action :verify_webhook_origin

    def message
      adapter = WhatsAppAdapter::Inbound.new

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
      adapter.consume(whats_app_webhook_params) { |message| message.contributor.reply(adapter) }
    end

    private

    def webhook_params
      params.permit(:AccountSid, :ApiVersion, :Body, :From, :Level, :MessageSid, :NumMedia, :NumSegments, :ParentAccountSid,
                    :Payload, :PayloadType, :ProfileName, :ReferralNumMedia, :Sid, :SmsMessageSid, :SmsSid, :SmsStatus,
                    :Timestamp, :To, :WaId)
    end

    def verify_webhook_origin
      auth_token = Setting.twilio_auth_token
      validator = Twilio::Security::RequestValidator.new(auth_token)
      url = "https://#{Setting.application_host}/whats_app/webhook"
      params = webhook_params.to_h
      twilio_signature = request.headers['X-Twilio-Signature']
      raise ActionController::BadRequest unless validator.validate(url, params, twilio_signature)
    end
  end
end

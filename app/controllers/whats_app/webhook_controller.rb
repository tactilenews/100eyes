# frozen_string_literal: true

module WhatsApp
  class WebhookController < ApplicationController
    skip_before_action :require_login, :verify_authenticity_token

    def message
      adapter = WhatsAppAdapter::Inbound.new

      adapter.on(WhatsAppAdapter::UNKNOWN_CONTRIBUTOR) do |whats_app_phone_number|
        exception = WhatsAppAdapter::UnknownContributorError.new(whats_app_phone_number: whats_app_phone_number)
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
                    :Timestamp, :To, :WaId, *media_params)
    end

    def media_params
      indeces_of_media = params[:NumMedia].to_i
      indeces_of_media.times.collect do |index|
        ["MediaContentType#{index}".to_sym, "MediaUrl#{index}".to_sym]
      end.flatten
    end
  end
end

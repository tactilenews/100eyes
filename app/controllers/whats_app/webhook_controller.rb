# frozen_string_literal: true

module WhatsApp
  class WebhookController < ApplicationController
    skip_before_action :require_login, :verify_authenticity_token
    UNSUCCESSFUL_DELIVERY = %w[undelivered failed].freeze

    def message
      adapter = WhatsAppAdapter::Inbound.new

      adapter.on(WhatsAppAdapter::UNKNOWN_CONTRIBUTOR) do |whats_app_phone_number|
        handle_unknown_contributor(whats_app_phone_number)
      end

      adapter.on(WhatsAppAdapter::RESPONDING_TO_TEMPLATE_MESSAGE) do |contributor, text|
        handle_respond_to_template_message(contributor, text)
      end

      adapter.on(WhatsAppAdapter::UNSUPPORTED_CONTENT) do |contributor|
        WhatsAppAdapter::Outbound.send_unsupported_content_message!(contributor)
      end

      adapter.on(WhatsAppAdapter::UNSUBSCRIBE_CONTRIBUTOR) do |contributor|
        handle_unsubscribe_contributor(contributor)
      end

      adapter.on(WhatsAppAdapter::SUBSCRIBE_CONTRIBUTOR) do |contributor|
        handle_subscribe_contributor(contributor)
      end

      whats_app_message_params = message_params.to_h.transform_keys(&:underscore)
      adapter.consume(whats_app_message_params) { |message| message.contributor.reply(adapter) }
    end

    def errors
      return unless error_params['Level'] == 'ERROR'

      payload = JSON.parse(error_params['Payload'])
      parameters = payload.with_indifferent_access.dig(:webhook, :request, :parameters)
      exception = WhatsAppAdapter::TwilioError.new(error_code: payload['error_code'])
      ErrorNotifier.report(exception,
                           context: {
                             channel_to_address: parameters&.dig(:channelToAddress),
                             more_info: payload['more_info'],
                             error_sid: error_params['Sid'],
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

    def message_params
      params.permit(:AccountSid, :ApiVersion, :Body, :ButtonText, :ButtonPayload, :From, :Latitude, :Longitude,
                    :MediaContentType0, :MediaUrl0, :MessageSid, :NumMedia, :NumSegments, :ProfileName,
                    :ReferralNumMedia, :SmsMessageSid, :SmsSid, :SmsStatus, :To, :WaId)
    end

    def error_params
      params.permit(:AccountSid, :Level, :ParentAccountSid, :Payload, :PayloadType, :Sid, :Timestamp)
    end

    def status_params
      params.permit(:AccountSid, :ApiVersion, :ChannelInstallSid, :ChannelPrefix, :ChannelToAddress, :ErrorCode, :EventType,
                    :From, :MessageSid, :MessageStatus, :SmsSid, :SmsStatus, :To)
    end

    def handle_unknown_contributor(whats_app_phone_number)
      exception = WhatsAppAdapter::UnknownContributorError.new(whats_app_phone_number: whats_app_phone_number)
      ErrorNotifier.report(exception)
    end

    def handle_respond_to_template_message(contributor, text)
      contributor.update!(whats_app_message_template_responded_at: Time.current, whats_app_template_message_sent_at: nil)

      if text.strip.eql?(I18n.t('adapter.whats_app.quick_reply_button_text.more_info'))
        WhatsAppAdapter::Outbound.send_more_info_message!(contributor)
      else
        message = contributor.received_messages.first
        WhatsAppAdapter::Outbound.send!(message)
      end
    end

    def handle_unsubscribe_contributor(contributor)
      contributor.update!(deactivated_at: Time.current)
      WhatsAppAdapter::Outbound.send_unsubsribed_successfully_message!(contributor)
      ContributorMarkedInactive.with(contributor_id: contributor.id).deliver_later(User.all)
      User.admin.find_each do |admin|
        PostmarkAdapter::Outbound.contributor_marked_as_inactive!(admin, contributor)
      end
    end

    def handle_subscribe_contributor(contributor)
      if contributor.deactivated_by_user.present?
        exception = StandardError.new(
          "Contributor #{contributor.name} has been deactivated by #{contributor.deactivated_by_user.name} and has tried to re-subscribe"
        )
        ErrorNotifier.report(exception)
        return
      end

      contributor.update!(deactivated_at: nil)
      WhatsAppAdapter::Outbound.send_welcome_message!(contributor)
      ContributorSubscribed.with(contributor_id: contributor.id).deliver_later(User.all)
      User.admin.find_each do |admin|
        PostmarkAdapter::Outbound.contributor_subscribed!(admin, contributor)
      end
    end
  end
end

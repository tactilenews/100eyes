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

      adapter.on(WhatsAppAdapter::REQUEST_FOR_MORE_INFO) do |contributor|
        handle_request_for_more_info(contributor)
      end

      adapter.on(WhatsAppAdapter::REQUEST_TO_RECEIVE_MESSAGE) do |contributor, twilio_message_sid|
        handle_request_to_receive_message(contributor, twilio_message_sid)
      end

      adapter.on(WhatsAppAdapter::UNSUPPORTED_CONTENT) do |contributor|
        WhatsAppAdapter::Outbound.send_unsupported_content_message!(contributor)
      end

      adapter.on(WhatsAppAdapter::UNSUBSCRIBE_CONTRIBUTOR) do |contributor|
        handle_unsubsribe_contributor(contributor)
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

    def three_sixty_dialog_status
      Rails.logger.debug params
      head :ok
    end

    private

    def message_params
      params.permit(:AccountSid, :ApiVersion, :Body, :ButtonText, :ButtonPayload, :From, :Latitude, :Longitude,
                    :MediaContentType0, :MediaUrl0, :MessageSid, :NumMedia, :NumSegments,
                    :OriginalRepliedMessageSender, :OriginalRepliedMessageSid, :ProfileName,
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

    def handle_request_for_more_info(contributor)
      contributor.update!(whats_app_message_template_responded_at: Time.current)

      WhatsAppAdapter::Outbound.send_more_info_message!(contributor)
    end

    def handle_request_to_receive_message(contributor, twilio_message_sid)
      contributor.update!(whats_app_message_template_responded_at: Time.current, whats_app_message_template_sent_at: nil)

      message = (send_requested_message(contributor, twilio_message_sid) if twilio_message_sid)
      WhatsAppAdapter::Outbound.send!(message || contributor.received_messages.first)
    end

    def handle_unsubsribe_contributor(contributor)
      contributor.update!(deactivated_at: Time.current)

      WhatsAppAdapter::Outbound.send_unsubsribed_successfully_message!(contributor)
      ContributorMarkedInactive.with(contributor_id: contributor.id).deliver_later(User.all)
      User.admin.find_each do |admin|
        PostmarkAdapter::Outbound.contributor_marked_as_inactive!(admin, contributor)
      end
    end

    def handle_subscribe_contributor(contributor)
      contributor.update!(deactivated_at: nil, whats_app_message_template_responded_at: Time.current)

      WhatsAppAdapter::Outbound.send_welcome_message!(contributor)
      ContributorSubscribed.with(contributor_id: contributor.id).deliver_later(User.all)
      User.admin.find_each do |admin|
        PostmarkAdapter::Outbound.contributor_subscribed!(admin, contributor)
      end
    end

    def send_requested_message(contributor, twilio_message_sid)
      message_text = fetch_message_from_twilio(twilio_message_sid)

      request_title = message_text.scan(/„[^"]*“/).first&.gsub('„', '')&.gsub('“', '')
      request = Request.find_by(title: request_title)

      request&.messages&.where(recipient_id: contributor.id)&.first
    end

    def fetch_message_from_twilio(twilio_message_sid)
      twilio_instance = Twilio::REST::Client.new(Setting.twilio_api_key_sid, Setting.twilio_api_key_secret, Setting.twilio_account_sid)
      message = twilio_instance.messages(twilio_message_sid).fetch
      message.body
    rescue Twilio::REST::RestError => e
      ErrorNotifier.report(e)
      nil
    end
  end
end

# frozen_string_literal: true

module WhatsApp
  class ThreeSixtyDialogWebhookController < ApplicationController
    include WhatsAppHandleCallbacks

    skip_before_action :require_login, :verify_authenticity_token
    before_action :organization

    # rubocop:disable Metrics/AbcSize
    def message
      head :ok
      return if params['statuses'].present? # TODO: Do we want to handle statuses?

      handle_error(params['messages'].first['errors'].first) if params['messages'].first['errors'].present?

      adapter = WhatsAppAdapter::ThreeSixtyDialogInbound.new

      adapter.on(WhatsAppAdapter::ThreeSixtyDialogInbound::UNKNOWN_CONTRIBUTOR) do |whats_app_phone_number|
        handle_unknown_contributor(whats_app_phone_number)
      end

      adapter.on(WhatsAppAdapter::ThreeSixtyDialogInbound::REQUEST_FOR_MORE_INFO) do |contributor|
        handle_request_for_more_info(contributor, @organization)
      end

      adapter.on(WhatsAppAdapter::ThreeSixtyDialogInbound::REQUEST_TO_RECEIVE_MESSAGE) do |contributor|
        handle_request_to_receive_message(contributor)
      end

      adapter.on(WhatsAppAdapter::ThreeSixtyDialogInbound::UNSUPPORTED_CONTENT) do |contributor|
        WhatsAppAdapter::ThreeSixtyDialogOutbound.send_unsupported_content_message!(contributor, @organization)
      end

      # TODO: Update to API that passes in organization_id
      adapter.on(WhatsAppAdapter::ThreeSixtyDialogInbound::UNSUBSCRIBE_CONTRIBUTOR) do |contributor|
        UnsubscribeContributorJob.perform_later(@organization.id, contributor.id, WhatsAppAdapter::Outbound)
      end

      adapter.on(WhatsAppAdapter::ThreeSixtyDialogInbound::RESUBSCRIBE_CONTRIBUTOR) do |contributor|
        ResubscribeContributorJob.perform_later(@organization.id, contributor.id, WhatsAppAdapter::Outbound)
      end

      adapter.consume(@organization, message_params.to_h) { |message| message.contributor.reply(adapter) }
    end
    # rubocop:enable Metrics/AbcSize

    def create_api_key
      channel_ids = create_api_key_params[:channels].split('[').last.split(']').last.split(',')
      client_id = create_api_key_params[:client]
      organization.update!(three_sixty_dialog_client_id: client_id)
      channel_ids.each do |channel_id|
        WhatsAppAdapter::CreateApiKey.perform_later(organization_id: @organization.id, channel_id: channel_id)
      end
      render 'onboarding/success'
    end

    private

    def organization
      @organization ||= Organization.find(params['organization_id'])
    end

    def message_params
      params.permit({ three_sixty_dialog_webhook:
                        [contacts: [:wa_id, { profile: [:name] }],
                         messages: [:from, :id, :type, :timestamp, { text: [:body] }, { context: %i[from id] },
                                    { button: [:text] }, { image: %i[id mime_type sha256 caption] },
                                    { voice: %i[id mime_type sha256] }, { video: %i[id mime_type sha256 caption] },
                                    { audio: %i[id mime_type sha256] }, { errors: %i[code details title] },
                                    { document: %i[filename id mime_type sha256] }, { location: %i[latitude longitude] },
                                    { contacts: [{ org: {} }, { addresses: [] }, { emails: [] }, { ims: [] },
                                                 { phones: %i[phone type wa_id] }, { urls: [] },
                                                 { name: %i[first_name formatted_name last_name] }] }]] },
                    contacts: [:wa_id, { profile: [:name] }],
                    messages: [:from, :id, :type, :timestamp, { text: [:body] }, { context: %i[from id] },
                               { button: [:text] }, { image: %i[id mime_type sha256 caption] },
                               { voice: %i[id mime_type sha256] }, { video: %i[id mime_type sha256 caption] },
                               { audio: %i[id mime_type sha256] }, { errors: %i[code details title] },
                               { document: %i[filename id mime_type sha256] }, { location: %i[latitude longitude] },
                               { contacts: [{ org: {} }, { addresses: [] }, { emails: [] }, { ims: [] },
                                            { phones: %i[phone type wa_id] }, { urls: [] },
                                            { name: %i[first_name formatted_name last_name] }] }])
    end

    def create_api_key_params
      params.permit(:client, :channels, :revoked)
    end

    def handle_error(error)
      exception = WhatsAppAdapter::ThreeSixtyDialogError.new(error_code: error['code'], message: error['title'])
      ErrorNotifier.report(exception, context: { details: error['details'] })
    end

    def handle_request_to_receive_message(contributor)
      contributor.update!(whats_app_message_template_responded_at: Time.current, whats_app_message_template_sent_at: nil)

      WhatsAppAdapter::ThreeSixtyDialogOutbound.send!(contributor.received_messages.first)
    end
  end
end

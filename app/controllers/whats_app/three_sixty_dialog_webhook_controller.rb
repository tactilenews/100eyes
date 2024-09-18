# frozen_string_literal: true

module WhatsApp
  class ThreeSixtyDialogWebhookController < ApplicationController
    include WhatsAppHandleCallbacks

    skip_before_action :require_login, :verify_authenticity_token, :user_permitted?
    before_action :extract_components, only: :message

    def message
      head :ok
      return if @components[:statuses].present? # TODO: Handle statuses

      handle_error(@components[:errors].first) and return if @components[:errors].present?

      WhatsAppAdapter::ProcessWebhook.perform_later(organization_id: @organization.id, components: @components)
    end

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

    def extract_components
      @components = message_params.to_h.with_indifferent_access[:entry].first[:changes].first[:value]
    end

    def message_params
      params.permit(:organization_id, :object,
                    entry: [:id, {
                      changes: [:field, {
                        value: [:messaging_product,
                                { metadata: %i[display_phone_number phone_number_id] },
                                { contacts: [:wa_id, { profile: [:name] }],
                                  messages: [:from, :id, :type, :timestamp,
                                             { text: [:body] }, { button: %i[payload text] },
                                             { image: %i[id mime_type sha256 caption] }, { voice: %i[id mime_type sha256] },
                                             { video: %i[id mime_type sha256 caption] }, { audio: %i[id mime_type sha256] },
                                             { document: %i[filename id mime_type sha256] }, { location: %i[latitude longitude] },
                                             { contacts: [{ org: {} }, { addresses: [] }, { emails: [] }, { ims: [] },
                                                          { phones: %i[phone type wa_id] }, { urls: [] },
                                                          { name: %i[first_name formatted_name last_name] }] },
                                             { context: %i[from id] }],
                                  statuses: [:id, :status, :timestamp, :expiration_timestamp, :recipient_id,
                                             { conversation: [:id, { origin: [:type] }] },
                                             { pricing: %i[billable pricing_model category] }],
                                  errors: [:code, :title, :message, :href, { error_data: [:details] }] }]
                      }]
                    }])
    end

    def create_api_key_params
      params.permit(:client, :channels, :revoked)
    end

    def handle_error(error)
      exception = WhatsAppAdapter::ThreeSixtyDialogError.new(error_code: error[:code], message: error[:title])
      ErrorNotifier.report(exception, context: { details: error[:error_data][:details] })
    end

    def handle_request_to_receive_message(contributor)
      contributor.update!(whats_app_message_template_responded_at: Time.current, whats_app_message_template_sent_at: nil)

      WhatsAppAdapter::ThreeSixtyDialogOutbound.send!(contributor.received_messages.first)
    end

    def handle_request_for_more_info(contributor, organization)
      contributor.update!(whats_app_message_template_responded_at: Time.current)

      WhatsAppAdapter::ThreeSixtyDialogOutbound.send_more_info_message!(contributor, organization)
    end
  end
end

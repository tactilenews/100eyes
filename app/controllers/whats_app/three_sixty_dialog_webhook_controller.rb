# frozen_string_literal: true

module WhatsApp
  class ThreeSixtyDialogWebhookController < ApplicationController
    skip_before_action :require_login, :verify_authenticity_token, :user_permitted?
    before_action :extract_components, only: :message

    def message
      head :ok
      return if @components[:statuses].present? # TODO: Handle statuses

      handle_error(@components[:errors].first) and return if @components[:errors].present?

      WhatsAppAdapter::ThreeSixtyDialog::ProcessWebhookJob.perform_later(organization_id: @organization.id, components: @components)
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
                                             { sticker: %i[id mime_type sha256 animated] },
                                             { context: %i[from id] }],
                                  statuses: [:id, :status, :timestamp, :expiration_timestamp, :recipient_id,
                                             { conversation: [:id, { origin: [:type] }] },
                                             { pricing: %i[billable pricing_model category] }],
                                  errors: [:code, :title, :message, :href, { error_data: [:details] }] }]
                      }]
                    }])
    end

    def handle_error(error)
      exception = WhatsAppAdapter::ThreeSixtyDialogError.new(error_code: error[:code], message: error[:title])
      ErrorNotifier.report(exception, context: { details: error[:error_data][:details] })
    end
  end
end

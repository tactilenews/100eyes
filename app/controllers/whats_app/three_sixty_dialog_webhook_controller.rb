# frozen_string_literal: true

module WhatsApp
  class ThreeSixtyDialogWebhookController < ApplicationController
    skip_before_action :require_login, :verify_authenticity_token, :user_permitted?
    before_action :extract_components, only: :message

    SUCCESSFUL_DELIVERY = %w[sent delivered read].freeze
    UNSUCCESSFUL_DELIVERY = %w[undelivered failed].freeze
    INVALID_MESSAGE_RECIPIENT_ERROR_CODE = 131_026 # https://docs.360dialog.com/docs/useful/api-error-message-list#type-message-undeliverable

    def message
      head :ok
      handle_statuses and return if @components[:statuses].present?
      handle_errors(@components[:errors]) and return if @components[:errors].present?

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
                                { metadata: %i[display_phone_number phone_number_id],
                                  contacts: [:wa_id, { profile: [:name] }],
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
                                             { pricing: %i[billable pricing_model category] },
                                             { errors: [:code, :title, :message, :href, { error_data: [:details] }] }],
                                  errors: [:code, :title, :message, :href, { error_data: [:details] }] }]

                      }]
                    }])
    end

    def handle_statuses
      statuses = @components[:statuses]
      statuses.each do |delivery_receipt|
        invalid_recipient_error = delivery_receipt[:errors]&.select { |error| error[:code].to_i.eql?(INVALID_MESSAGE_RECIPIENT_ERROR_CODE) }
        mark_inactive_contributor_inactive(delivery_receipt) if invalid_recipient_error.present?
        handle_errors(delivery_receipt[:errors]) if delivery_receipt[:status].in?(UNSUCCESSFUL_DELIVERY)
        handle_successful_delivery(delivery_receipt) if delivery_receipt[:status].in?(SUCCESSFUL_DELIVERY)
      end
    end

    def handle_errors(errors)
      errors.each do |error|
        exception = WhatsAppAdapter::ThreeSixtyDialogError.new(error_code: error[:code], message: error[:message])
        ErrorNotifier.report(exception, context: { details: error[:error_data][:details], title: error[:title] })
      end
    end

    def mark_inactive_contributor_inactive(status)
      contributor = @organization.contributors.find_by(whats_app_phone_number: "+#{status[:recipient_id]}")
      MarkInactiveContributorInactiveJob.perform_later(organization_id: @organization.id, contributor_id: contributor.id)
    end

    def handle_successful_delivery(delivery_receipt)
      WhatsAppAdapter::ThreeSixtyDialog::ProcessMessageStatusJob.perform_later(organization_id: @organization.id,
                                                                               delivery_receipt: delivery_receipt)
    end
  end
end

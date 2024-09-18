# frozen_string_literal: true

module WhatsAppAdapter
  class ProcessWebhook < ApplicationJob
    def perform(organization_id:, components:)
      organization = Organization.find_by(id: organization_id)
      return unless organization

      adapter = WhatsAppAdapter::ThreeSixtyDialogInbound.new

      adapter.on(WhatsAppAdapter::ThreeSixtyDialogInbound::UNKNOWN_CONTRIBUTOR) do |whats_app_phone_number|
        handle_unknown_contributor(whats_app_phone_number)
      end

      adapter.on(WhatsAppAdapter::ThreeSixtyDialogInbound::REQUEST_FOR_MORE_INFO) do |contributor|
        handle_request_for_more_info(contributor, organization)
      end

      adapter.on(WhatsAppAdapter::ThreeSixtyDialogInbound::REQUEST_TO_RECEIVE_MESSAGE) do |contributor|
        handle_request_to_receive_message(contributor)
      end

      adapter.on(WhatsAppAdapter::ThreeSixtyDialogInbound::UNSUPPORTED_CONTENT) do |contributor|
        WhatsAppAdapter::ThreeSixtyDialogOutbound.send_unsupported_content_message!(contributor, organization)
      end

      adapter.on(WhatsAppAdapter::ThreeSixtyDialogInbound::UNSUBSCRIBE_CONTRIBUTOR) do |contributor|
        UnsubscribeContributorJob.perform_later(organization.id, contributor.id, WhatsAppAdapter::ThreeSixtyDialogOutbound)
      end

      adapter.on(WhatsAppAdapter::ThreeSixtyDialogInbound::RESUBSCRIBE_CONTRIBUTOR) do |contributor|
        ResubscribeContributorJob.perform_later(organization.id, contributor.id, WhatsAppAdapter::ThreeSixtyDialogOutbound)
      end

      adapter.consume(organization, components) { |message| message.contributor.reply(adapter) }
    end
  end
end

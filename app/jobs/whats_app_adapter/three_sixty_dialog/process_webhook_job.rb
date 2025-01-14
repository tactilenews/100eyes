# frozen_string_literal: true

module WhatsAppAdapter
  module ThreeSixtyDialog
    class ProcessWebhookJob < ApplicationJob
      attr_reader :organization, :whats_app_message

      def perform(organization_id:, components:)
        @organization = Organization.find_by(id: organization_id)

        @whats_app_message = components
        adapter = WhatsAppAdapter::ThreeSixtyDialogInbound.new

        adapter.on(WhatsAppAdapter::ThreeSixtyDialogInbound::UNKNOWN_CONTRIBUTOR) do
          handle_unknown_contributor
        end

        adapter.on(WhatsAppAdapter::ThreeSixtyDialogInbound::REQUEST_FOR_MORE_INFO) do
          handle_request_for_more_info
        end

        adapter.on(WhatsAppAdapter::ThreeSixtyDialogInbound::REQUEST_TO_RECEIVE_MESSAGE) do
          handle_request_to_receive_message
        end

        adapter.on(WhatsAppAdapter::ThreeSixtyDialogInbound::UNSUPPORTED_CONTENT) do
          WhatsAppAdapter::ThreeSixtyDialogOutbound.send_unsupported_content_message!(contributor, organization)
        end

        adapter.on(WhatsAppAdapter::ThreeSixtyDialogInbound::UNSUBSCRIBE_CONTRIBUTOR) do
          UnsubscribeContributorJob.perform_later(organization.id, contributor.id, WhatsAppAdapter::ThreeSixtyDialogOutbound)
        end

        adapter.on(WhatsAppAdapter::ThreeSixtyDialogInbound::RESUBSCRIBE_CONTRIBUTOR) do
          ResubscribeContributorJob.perform_later(organization.id, contributor.id, WhatsAppAdapter::ThreeSixtyDialogOutbound)
        end

        adapter.consume(organization, components) { |message| message.contributor.reply(adapter) }
      end

      private

      def whats_app_phone_number
        whats_app_message[:contacts].first[:wa_id].phony_normalized
      end

      def contributor
        organization.contributors.find_by(whats_app_phone_number: whats_app_phone_number)
      end

      def handle_unknown_contributor
        exception = WhatsAppAdapter::UnknownContributorError.new(whats_app_phone_number: whats_app_phone_number)
        ErrorNotifier.report(exception)
      end

      def handle_request_to_receive_message
        contributor.update!(whats_app_message_template_responded_at: Time.current, whats_app_message_template_sent_at: nil)
        external_id = whats_app_message[:messages].first.dig(:context, :id)
        message = Message.find_by(external_id: external_id) if external_id
        WhatsAppAdapter::ThreeSixtyDialogOutbound.send!(message || contributor.received_messages.first)
      end

      def handle_request_for_more_info
        contributor.update!(whats_app_message_template_responded_at: Time.current)

        WhatsAppAdapter::ThreeSixtyDialogOutbound.send_more_info_message!(contributor, organization)
      end
    end
  end
end

# frozen_string_literal: true

module WhatsAppAdapter
  module ThreeSixtyDialog
    class HandleEphemeralDataJob < ApplicationJob
      attr_reader :contributor, :organization, :message

      def perform(type:, contributor_id:, external_message_id: nil)
        @contributor = Contributor.find(contributor_id)
        @organization = contributor.organization
        @message = Message.find_by(external_id: external_message_id) if external_message_id

        case type
        when :request_for_more_info
          handle_request_for_more_info
        when :unsubscribe
          handle_unsubscribe
        when :resubscribe
          handle_resubscribe
        when :request_to_receive_message
          handle_request_to_receive_message
        end
      end

      private

      def handle_request_for_more_info
        contributor.update!(whats_app_message_template_responded_at: Time.current)
        WhatsAppAdapter::ThreeSixtyDialogOutbound.send_more_info_message!(contributor)
      end

      def handle_unsubscribe
        UnsubscribeContributorJob.perform_later(organization.id, contributor.id, WhatsAppAdapter::ThreeSixtyDialogOutbound)
      end

      def handle_resubscribe
        ResubscribeContributorJob.perform_later(organization.id, contributor.id, WhatsAppAdapter::ThreeSixtyDialogOutbound)
      end

      def handle_request_to_receive_message
        contributor.update!(whats_app_message_template_responded_at: Time.current, whats_app_message_template_sent_at: nil)
        WhatsAppAdapter::ThreeSixtyDialogOutbound.send!(message || contributor.received_messages.first)
      end
    end
  end
end

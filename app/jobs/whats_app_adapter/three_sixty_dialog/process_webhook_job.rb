# frozen_string_literal: true

module WhatsAppAdapter
  module ThreeSixtyDialog
    class ProcessWebhookJob < ApplicationJob
      attr_reader :organization, :whats_app_message

      def perform(organization_id:, components:)
        @organization = Organization.find(organization_id)

        @whats_app_message = components
        adapter = WhatsAppAdapter::ThreeSixtyDialogInbound.new

        adapter.consume(organization, components) { |message| message.contributor.reply(adapter) }
      end
    end
  end
end

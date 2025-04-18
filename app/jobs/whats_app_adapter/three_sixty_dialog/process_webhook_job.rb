# frozen_string_literal: true

module WhatsAppAdapter
  module ThreeSixtyDialog
    class ProcessWebhookJob < ApplicationJob
      def perform(organization_id:, components:)
        organization = Organization.find(organization_id)

        whats_app_message = components
        adapter = WhatsAppAdapter::ThreeSixtyDialogInbound.new

        adapter.consume(organization, whats_app_message)
      end
    end
  end
end

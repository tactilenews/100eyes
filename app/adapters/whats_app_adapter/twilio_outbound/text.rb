# frozen_string_literal: true

module WhatsAppAdapter
  class TwilioOutbound
    class Text < ApplicationJob
      queue_as :default

      def perform(organization_id:, contributor_id:, text:, message: nil)
        organization = Organization.find(organization_id)
        contributor = organization.contributors.find(contributor_id)

        response = organization.twilio_instance.messages.create(
          from: "whatsapp:#{organization.whats_app_server_phone_number}",
          body: text,
          to: "whatsapp:#{contributor.whats_app_phone_number}"
        )
        return unless message

        message.update(external_id: response.sid)
      rescue ActiveRecord::RecordNotFound => e
        ErrorNotifier.report(e)
      end
    end
  end
end

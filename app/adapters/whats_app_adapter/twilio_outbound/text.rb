# frozen_string_literal: true

module WhatsAppAdapter
  class TwilioOutbound
    class Text < ApplicationJob
      queue_as :default

      def perform(contributor_id:, text:, message: nil)
        contributor = Contributor.find(contributor_id)
        organization = contributor.organization

        response = organization.twilio_instance.messages.create(
          from: "whatsapp:#{organization.whats_app_server_phone_number}",
          body: text,
          to: "whatsapp:#{contributor.whats_app_phone_number}"
        )
        return unless message

        message.update(external_id: response.sid)
      end
    end
  end
end

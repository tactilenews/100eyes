# frozen_string_literal: true

module WhatsAppAdapter
  class Outbound
    class Text < ApplicationJob
      queue_as :default

      def self.twilio_instance(organization)
        @twilio_instance = Twilio::REST::Client.new(organization.twilio_api_key_sid, organization.twilio_api_key_secret,
                                                    organization.twilio_account_sid)
      end

      def perform(organization_id:, contributor_id:, text:, message: nil)
        organization = Organization.find_by(id: organization_id)
        return unless organization

        contributor = organization.contributors.find_by(id: contributor_id)
        return unless contributor

        response = self.class.twilio_instance(organization).messages.create(
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

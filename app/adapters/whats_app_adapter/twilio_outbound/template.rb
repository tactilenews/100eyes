# frozen_string_literal: true

module WhatsAppAdapter
  class TwilioOutbound
    class Template < ApplicationJob
      queue_as :default

      def perform(organization_id:, contributor_id:, content_sid:, message:)
        organization = Organization.find(organization_id)
        contributor = organization.contributors.find(contributor_id)

        response = organization.twilio_instance.messages.create(
          content_sid: content_sid,
          from: "whatsapp:#{organization.whats_app_server_phone_number}",
          to: "whatsapp:#{contributor.whats_app_phone_number}",
          content_variables: {
            '1' => contributor.first_name,
            '2' => message.request.title
          }.to_json
        )

        message.update(external_id: response.sid)
      rescue ActiveRecord::RecordNotFound => e
        ErrorNotifier.report(e)
      end
    end
  end
end

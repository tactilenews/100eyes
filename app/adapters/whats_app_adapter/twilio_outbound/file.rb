# frozen_string_literal: true

module WhatsAppAdapter
  class TwilioOutbound
    class File < ApplicationJob
      queue_as :default

      def perform(organization_id:, contributor_id:, message:)
        organization = Organization.find(organization_id)
        contributor = organization.contributors.find(contributor_id)

        responses = message.files.each_with_index.map do |file, index|
          organization.twilio_instance.messages.create(
            from: "whatsapp:#{organization.whats_app_server_phone_number}",
            body: index.zero? ? message.text : '',
            to: "whatsapp:#{contributor.whats_app_phone_number}",
            media_url: Rails.application.routes.url_helpers.rails_blob_url(file.attachment.blob,
                                                                           host: ENV.fetch('APPLICATION_HOSTNAME', 'localhost:3000'))
          )
        end

        message.update(external_id: responses.first.sid)
      rescue ActiveRecord::RecordNotFound => e
        ErrorNotifier.report(e)
      end
    end
  end
end

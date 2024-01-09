# frozen_string_literal: true

module WhatsAppAdapter
  class Outbound
    class File < ApplicationJob
      queue_as :default

      def self.twilio_instance
        @twilio_instance = Twilio::REST::Client.new(Setting.twilio_api_key_sid, Setting.twilio_api_key_secret, Setting.twilio_account_sid)
      end

      def perform(contributor_id:, message:)
        contributor = Contributor.find(contributor_id)
        return unless contributor

        responses = message.files.each_with_index.map do |file, index|
          self.class.twilio_instance.messages.create(
            from: "whatsapp:#{Setting.whats_app_server_phone_number}",
            body: index.zero? ? message.text : '',
            to: "whatsapp:#{contributor.whats_app_phone_number}",
            media_url: Rails.application.routes.url_helpers.rails_blob_url(file.attachment.blob, host: Setting.application_host)
          )
        end

        message.update(external_id: responses.first.sid)
      end
    end
  end
end

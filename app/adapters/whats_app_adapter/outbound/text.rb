# frozen_string_literal: true

module WhatsAppAdapter
  class Outbound
    class Text < ApplicationJob
      queue_as :default

      def self.twilio_instance
        @twilio_instance = Twilio::REST::Client.new(Setting.twilio_api_key_sid, Setting.twilio_api_key_secret, Setting.twilio_account_sid)
      end

      def perform(contributor_id:, text:, message: nil)
        contributor = Contributor.find_by(id: contributor_id)
        return unless contributor

        response = self.class.twilio_instance.messages.create(
          from: "whatsapp:#{Setting.whats_app_server_phone_number}",
          body: text,
          to: "whatsapp:#{contributor.whats_app_phone_number}"
        )
        return unless message

        message.update(external_id: response.sid)
      end
    end
  end
end

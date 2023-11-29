# frozen_string_literal: true

module WhatsAppAdapter
  class Outbound
    class Text < ApplicationJob
      queue_as :default

      def self.twilio_instance
        @twilio_instance = Twilio::REST::Client.new(Setting.twilio_api_key_sid, Setting.twilio_api_key_secret, Setting.twilio_account_sid)
      end

      def perform(contributor_id:, text:)
        contributor = Contributor.find(contributor_id)
        return unless contributor

        self.class.twilio_instance.messages.create(
          from: "whatsapp:#{Setting.whats_app_server_phone_number}",
          body: text,
          to: "whatsapp:#{contributor.whats_app_phone_number}"
        )
      end
    end
  end
end

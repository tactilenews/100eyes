# frozen_string_literal: true

module WhatsAppAdapter
  class Outbound
    class Text < ApplicationJob
      queue_as :default

      def self.twilio_instance
        @twilio_instance = Twilio::REST::Client.new(Setting.twilio_account_sid, Setting.twilio_auth_token)
      end

      def perform(recipient:, text:)
        self.class.twilio_instance.messages.create(
          from: "whatsapp:#{Setting.whats_app_server_phone_number}",
          body: text,
          to: "whatsapp:#{recipient.whats_app_phone_number}"
        )
      end
    end
  end
end
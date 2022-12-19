# frozen_string_literal: true

module WhatsAppAdapter
  class Outbound
    def self.send!(message)
      recipient = message&.recipient
      return unless contributor_can_receive_messages?(recipient)

      if message.files.present?
        # implement in 2nd step
      else
        WhatsAppAdapter::Outbound::Text.perform_later(recipient: recipient, text: message.text)
      end
    end

    def self.contributor_can_receive_messages?(recipient)
      recipient&.whats_app_phone_number.present?
    end
  end
end

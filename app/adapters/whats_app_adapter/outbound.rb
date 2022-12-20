# frozen_string_literal: true

module WhatsAppAdapter
  class Outbound
    def self.send!(message)
      recipient = message&.recipient
      return unless contributor_can_receive_messages?(recipient)

      latest_message_received_at = recipient.latest_message_received_at
      text = if latest_message_received_at.blank? || latest_message_received_at < Time.current - 24.hours.ago
               recipient.update(whats_app_template_message_sent_at: Time.current)
               "Your #{Setting.project_name} code is 12345"
             else
               message.text
             end
      if message.files.present?
        # implement in 2nd step
      else
        WhatsAppAdapter::Outbound::Text.perform_later(recipient: recipient, text: text)
      end
    end

    def self.send_welcome_message!(contributor)
      return unless contributor_can_receive_messages?(contributor)

      welcome_message = [Setting.onboarding_success_heading, Setting.onboarding_success_text].join("\n")
      WhatsAppAdapter::Outbound::Text.perform_later(recipient: contributor, text: welcome_message)
    end

    def self.contributor_can_receive_messages?(recipient)
      recipient&.whats_app_phone_number.present? && recipient&.whats_app_onboarding_completed_at.present?
    end
  end
end

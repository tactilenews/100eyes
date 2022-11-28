# frozen_string_literal: true

module SignalAdapter
  class Outbound
    SEND_URL = URI.parse("#{Setting.signal_cli_rest_api_endpoint}/v2/send")

    def self.send!(message)
      recipient = message&.recipient
      return unless contributor_can_receive_messages?(recipient)

      if message.files.present?
        SignalAdapter::Outbound::File.perform_later(message: message)
      else
        SignalAdapter::Outbound::Text.perform_later(recipient: recipient, text: message.text)
      end
    end

    def self.send_unknown_content_message!(contributor)
      return unless contributor_can_receive_messages?(contributor)

      SignalAdapter::Outbound::Text.perform_later(recipient: contributor, text: Setting.signal_unknown_content_message)
    end

    def self.send_welcome_message!(contributor)
      return unless contributor_can_receive_messages?(contributor)

      welcome_message = [Setting.onboarding_success_heading, Setting.onboarding_success_text].join("\n")
      SignalAdapter::Outbound::Text.perform_later(recipient: contributor, text: welcome_message)
    end

    def self.contributor_can_receive_messages?(recipient)
      recipient&.signal_phone_number.present? && recipient.signal_onboarding_completed_at.present?
    end
  end
end

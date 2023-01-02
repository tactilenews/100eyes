# frozen_string_literal: true

module SignalAdapter
  class Outbound
    def self.send!(message)
      recipient = message&.recipient
      return unless contributor_can_receive_messages?(recipient)

      if message.files.present?
        conditionally_schedule(SignalAdapter::Outbound::File, message).perform_later(message: message)
      else
        conditionally_schedule(SignalAdapter::Outbound::Text, message).perform_later(recipient: recipient, text: message.text)
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

    def self.conditionally_schedule(message_type, message)
      message_type.try do |klass|
        message.request.schedule_send_for.present? ? klass.set(wait_until: message.request.schedule_send_for) : klass
      end
    end
  end
end

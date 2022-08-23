# frozen_string_literal: true

module ThreemaAdapter
  class Outbound < ApplicationJob
    queue_as :default

    def self.threema_instance
      @threema_instance ||= Threema.new
    end

    def self.send!(message)
      recipient = message.recipient
      return unless message.recipient&.threema_id

      perform_later(recipient: recipient, text: message.text)
    end

    def self.welcome_message(contributor)
      ["*#{Setting.find_by(var: :onboarding_success_heading)
                  .send("value_#{contributor.localization_tags.first}".to_sym).strip}*",
       Setting.find_by(var: :onboarding_success_text)
              .send("value_#{contributor.localization_tags.first}").to_sym].join("\n")
    end

    def self.send_welcome_message!(contributor)
      return unless contributor&.threema_id

      perform_later(text: welcome_message(contributor), recipient: contributor)
    end

    def perform(recipient:, text:)
      self.class.threema_instance.send(type: :text, threema_id: recipient.threema_id.upcase, text: text)
    end
  end
end

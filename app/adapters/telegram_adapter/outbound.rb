# frozen_string_literal: true

module TelegramAdapter
  class Outbound < ApplicationJob
    def self.send!(message)
      recipient = message.recipient
      return unless recipient&.telegram_id

      if message.request.image.attached?
        TelegramAdapter::Outbound::Photo.perform_later(text, recipient.telegram_id,
                                                       File.open(ActiveStorage::Blob.service.path_for(message.request.image.blob.key)))
      else
        TelegramAdapter::Outbound::Text.perform_later(text: message.text, recipient: recipient)
      end
    end

    def self.send_welcome_message!(contributor)
      return unless contributor&.telegram_id

      welcome_message = ["<b>#{Setting.onboarding_success_heading}</b>", Setting.onboarding_success_text].join("\n")
      TelegramAdapter::Outbound::Text.perform_later(text: welcome_message, recipient: contributor)
    end
  end
end

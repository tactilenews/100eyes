# frozen_string_literal: true

module TelegramAdapter
  class Outbound < ApplicationJob
    def self.send!(message)
      recipient = message.recipient
      return unless recipient&.telegram_id

      files = message.files
      if files.present?
          media = files.map { |file| ActiveStorage::Blob.service.path_for(file.attachment.blob.key) }
          TelegramAdapter::Outbound::Photo.perform_later(telegram_id: recipient.telegram_id,
                                                         media: media,
                                                         caption: message.text)
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

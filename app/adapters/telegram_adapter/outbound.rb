# frozen_string_literal: true

module TelegramAdapter
  class Outbound < ApplicationJob
    queue_as :default
    discard_on Telegram::Bot::Forbidden do |job|
      message = job.arguments.first[:message]
      message&.update(blocked: true)
    end

    def self.send!(message)
      recipient = message.recipient
      return unless recipient&.telegram_id

      if message.request.image.attached?
        TelegramAdapter::Outbound::Photo.perform_later(text, recipient.telegram_id,
                                                       File.open(ActiveStorage::Blob.service.path_for(message.request.image.blob.key)))
      else
        perform_later(text: message.text, recipient: recipient, message: message)
      end
    end

    def self.send_welcome_message!(contributor)
      return unless contributor&.telegram_id

      welcome_message = ["<b>#{Setting.onboarding_success_heading}</b>", Setting.onboarding_success_text].join("\n")
      perform_later(text: welcome_message, recipient: contributor)
    end

    def perform(text:, recipient:, message: nil)
      Telegram.bot.send_message(
        chat_id: recipient.telegram_id,
        text: text,
        parse_mode: :HTML
      )
    end
  end
end

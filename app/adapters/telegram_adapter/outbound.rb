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

      perform_later(text: message.text, recipient: recipient, message: message)
    end

    def self.send_welcome_message!(contributor)
      return unless contributor&.telegram_id

      welcome_message = ["<b>#{Setting.onboarding_success_heading}</b>", Setting.onboarding_success_text].join("\n")
      perform_later(text: welcome_message, recipient: contributor)
    end

    def perform(text:, recipient:, message: nil)
      if message.request.image
        send_photo(text, recipient.telegram_id, File.open("public/#{message.request.image_url}"))
      else
        send_message(recipient.telegram_id, text)
      end
    end

    def send_photo(caption, telegram_id, photo)
      Telegram.bot.send_photo(
        chat_id: telegram_id,
        photo: photo,
        caption: caption,
        parse_mode: :HTML
      )
    end

    def send_message(telegram_id, text)
      Telegram.bot.send_message(
        chat_id: telegram_id,
        text: text,
        parse_mode: :HTML
      )
    end
  end
end

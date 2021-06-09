# frozen_string_literal: true

module TelegramAdapter
  class Outbound < ApplicationJob
    queue_as :default
    discard_on Telegram::Bot::Forbidden do |job|
      message = job.arguments.first[:message]
      message.update(blocked: true) if message
    end

    def self.send!(message)
      perform_later(text: message.text, recipient: message.recipient, message: message)
    end

    def self.send_welcome_message!(contributor)
      welcome_message = ["<b>#{Setting.onboarding_success_heading}</b>", Setting.onboarding_success_text].join("\n")
      perform_later(text: welcome_message, recipient: contributor)
    end

    def perform(text:, recipient:, message: nil)
      return unless recipient&.telegram_id

      Telegram.bot.send_message(
        chat_id: recipient.telegram_id,
        text: text,
        parse_mode: :HTML
      )
    end
  end
end

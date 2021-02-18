# frozen_string_literal: true

module TelegramAdapter
  class Outbound < ApplicationJob
    queue_as :default
    discard_on Telegram::Bot::Forbidden do |job|
      message = job.arguments.first
      message.update(blocked: true)
    end

    def self.send!(message)
      perform_later(message)
    end

    def perform(message)
      recipient = message.recipient
      return unless recipient&.telegram_id

      Telegram.bot.send_message(
        chat_id: message.recipient.telegram_id,
        text: message.text
      )
    end
  end
end

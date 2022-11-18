# frozen_string_literal: true

module TelegramAdapter
  class Outbound
    class Text < ApplicationJob
      queue_as :default
      discard_on Telegram::Bot::Forbidden do |job|
        message = job.arguments.first[:message]
        message&.update(blocked: true)
      end

      def perform(text:, recipient:)
        Telegram.bot.send_message(
          chat_id: recipient.telegram_id,
          text: text,
          parse_mode: :HTML
        )
      end
    end
  end
end

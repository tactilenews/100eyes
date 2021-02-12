# frozen_string_literal: true

module TelegramAdapter
  class Outbound
    attr_reader :message

    delegate :recipient, to: :message

    def initialize(message:)
      @message = message
    end

    def send!
      return unless recipient&.telegram_id

      begin
        Telegram.bot.send_message(
          chat_id: recipient.telegram_id,
          text: message.text
        )
      rescue Telegram::Bot::Forbidden
        message.update(blocked: true)
      end
    end
  end
end

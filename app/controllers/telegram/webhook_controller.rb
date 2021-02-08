# frozen_string_literal: true

class Telegram::WebhookController < Telegram::Bot::UpdatesController
  def message(message)
    telegram_message = TelegramAdapter::Inbound.new(message)
    contributor = telegram_message.sender

    TelegramAdapter::Inbound.bounce!(chat) and return unless contributor

    respond_with :message, text: Setting.telegram_unknown_content_message if telegram_message.unknown_content
    contributor.reply(telegram_message)
  end
end

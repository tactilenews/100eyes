# frozen_string_literal: true

class Telegram::WebhookController < Telegram::Bot::UpdatesController
  def message(message)
    telegram_message = TelegramMessage.new(message)
    contributor = telegram_message.sender

    return respond_with :message, text: Setting.telegram_contributor_not_found_message unless contributor

    respond_with :message, text: Setting.telegram_unknown_content_message if telegram_message.unknown_content
    contributor.reply(telegram_message)
  end

  def start!(_data = nil, *)
    telegram_message = TelegramMessage.new(from: from, chat: chat)
    contributor = telegram_message.sender
    return if contributor

    respond_with :message, text: Setting.telegram_contributor_not_found_message
  end
end

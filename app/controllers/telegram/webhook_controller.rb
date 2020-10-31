# frozen_string_literal: true

class Telegram::WebhookController < Telegram::Bot::UpdatesController
  def message(message)
    tm = TelegramMessage.new(message)
    contributor = tm.sender

    return respond_with :message, text: 'Who are you?' unless contributor

    respond_with :message, text: Setting.telegram_unknown_content_message if tm.unknown_content
    contributor.reply(tm)
  end

  def start!(_data = nil, *)
    tm = TelegramMessage.new(from: from, chat: chat)
    contributor = tm.sender
    if contributor
      response = Setting.telegram_welcome_message
      respond_with :message, text: response.strip
    else
      respond_with :message, text: 'Who are you?'
    end
  end
end

# frozen_string_literal: true

class Telegram::WebhookController < Telegram::Bot::UpdatesController
  def message(message)
    tm = TelegramMessage.new(message)
    respond_with :message, text: Setting.telegram_unknown_content_message if tm.unknown_content
    contributor = tm.sender
    contributor.save!
    contributor.reply(tm)
  end

  def start!(_data = nil, *)
    tm = TelegramMessage.new(from: from, chat: chat)
    contributor = tm.sender
    contributor.save!
    response = Setting.telegram_welcome_message
    respond_with :message, text: response.strip
  end
end

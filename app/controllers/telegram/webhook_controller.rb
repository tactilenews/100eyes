# frozen_string_literal: true

class Telegram::WebhookController < Telegram::Bot::UpdatesController
  def message(message)
    tm = TelegramMessage.new(message)
    respond_with :message, text: Setting.telegram_unknown_content_message if tm.unknown_content
    user = tm.sender
    user.save!
    user.reply(tm)
  end

  def start!(_data = nil, *)
    tm = TelegramMessage.new(from: from, chat: chat)
    user = tm.sender
    user.save!
    response = Setting.telegram_welcome_message
    respond_with :message, text: response.strip
  end
end

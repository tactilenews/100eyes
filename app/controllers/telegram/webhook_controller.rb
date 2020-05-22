# frozen_string_literal: true

class Telegram::WebhookController < Telegram::Bot::UpdatesController
  def message(message)
    tm = TelegramMessage.new(message)
    user = tm.user
    user.save!
    user.reply_via_telegram(message)
  end

  def start!(_data = nil, *)
    tm = TelegramMessage.new(from: from, chat: chat)
    user = tm.user
    user.save!
    project_name = Rails.configuration.project_name
    response = I18n.t 'telegram.welcome_message', project_name: project_name
    respond_with :message, text: response.strip
  end
end

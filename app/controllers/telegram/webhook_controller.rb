# frozen_string_literal: true

class Telegram::WebhookController < Telegram::Bot::UpdatesController
  def message(message)
    tm = TelegramMessage.new(message)
    respond_with :message, text: I18n.t('telegram.unknown_content_message') if tm.unknown_content
    user = tm.sender
    user.save!
    user.reply(tm)
  end

  def start!(_data = nil, *)
    tm = TelegramMessage.new(from: from, chat: chat)
    user = tm.sender
    user.save!
    project_name = Setting.project_name
    response = I18n.t 'telegram.welcome_message', project_name: project_name
    respond_with :message, text: response.strip
  end
end

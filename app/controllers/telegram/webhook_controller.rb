# frozen_string_literal: true

class Telegram::WebhookController < Telegram::Bot::UpdatesController
  def message(message)
    telegram_chat_id = message['chat']['id']
    user = User.find_by(telegram_chat_id: telegram_chat_id)
    unless user
      user = User.new(
        telegram_chat_id: telegram_chat_id,
        telegram_id: message['from']['id'],
        first_name: from['first_name'],
        last_name: from['last_name'],
        username: from['username']
      )
      user.save!
    end
    Request.add_reply(user: user, answer: message['text'])
  end

  def start!(_data = nil, *)
    project_name = Rails.configuration.project_name
    response = I18n.t 'telegram.welcome_message', project_name: project_name
    respond_with :message, text: response.strip
  end
end

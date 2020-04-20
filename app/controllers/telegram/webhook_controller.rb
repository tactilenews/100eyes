# frozen_string_literal: true

class Telegram::WebhookController < Telegram::Bot::UpdatesController
  def message(message)
    telegram_chat_id = message['chat']['id']
    user = User.find_by(telegram_chat_id: telegram_chat_id)
    unless user
      user = User.new(
        telegram_chat_id: telegram_chat_id,
        telegram_id: message['from']['id']
      )
      user.save!
    end
    Request.add_reply(user: user, answer: message['text'])
  end

  def start!(_data = nil, *)
    response = from ? "Hello #{from['username']}!" : 'Hi there!'
    respond_with :message, text: response
  end
end

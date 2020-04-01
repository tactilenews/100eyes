# frozen_string_literal: true

class Telegram::WebhookController < Telegram::Bot::UpdatesController
  def message(message)
    chat_id = message['chat']['id']
    user = User.find_by(chat_id: chat_id)
    unless user
      user = User.new(chat_id: chat_id)
      user.save!
    end
    user.respond_feedback(answer: message['text'])
  end

  def start!(_data = nil, *)
    response = from ? "Hello #{from['username']}!" : 'Hi there!'
    respond_with :message, text: response
  end
end

# frozen_string_literal: true

class TelegramMessage
  attr_reader :user, :text, :photo

  def initialize(message)
    message = message.with_indifferent_access
    @text = message[:text] || message[:caption]
    @user = initialize_user(message)
  end

  def initialize_user(message)
    telegram_chat_id = message.dig(:chat, :id)
    telegram_id = message.dig(:from, :id)
    first_name = message.dig(:from, :first_name)
    last_name = message.dig(:from, :last_name)
    username = message.dig(:from, :username)
    user = User.find_by(telegram_id: telegram_id)
    if user
      user.username = username
      user.telegram_chat_id = telegram_chat_id
    else
      user = User.new(
        telegram_id: telegram_id,
        telegram_chat_id: telegram_chat_id,
        username: username,
        first_name: first_name,
        last_name: last_name
      )
    end
    user
  end
end

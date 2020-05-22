# frozen_string_literal: true

class TelegramMessage
  attr_reader :user, :text, :reply, :photos

  def initialize(message)
    message = message.with_indifferent_access
    @text = message[:text] || message[:caption]
    @user = initialize_user(message)
    @reply = initialize_reply(message)
    @photos = initialize_photos(message)
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

  def initialize_reply(message)
    media_group_id = message['media_group_id']
    reply = Reply.find_by(telegram_media_group_id: media_group_id) if media_group_id
    reply ||= Reply.new(text: text, user: user, request: request, telegram_media_group_id: media_group_id)
    reply
  end

  def initialize_photos(message)
    return [] unless messsage['photo']

    [Photo.new(telegram_message: message)]
  end
end

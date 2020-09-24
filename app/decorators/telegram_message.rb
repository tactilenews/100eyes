# frozen_string_literal: true

##
# Telegram represents a message containing multiple photos as multiple
# messages each containing a single photo.
class TelegramMessage
  UNKNOWN_CONTENT_KEYS = %w[
    animation audio document sticker video video_note
    contact dice game poll venue location
    invoice successful_payment passport_data
  ].freeze
  attr_reader :sender, :text, :message, :photos, :unknown_content, :voice

  def self.from(raw_data)
    new(JSON.parse(raw_data.download))
  end

  def initialize(telegram_message)
    telegram_message = telegram_message.with_indifferent_access
    @text = telegram_message[:text] || telegram_message[:caption]
    @sender = initialize_user(telegram_message)
    @unknown_content = initialize_unknown_content(telegram_message)
    @message = initialize_message(telegram_message)
    @photos = initialize_photos(telegram_message)
    @voice = initialize_voice(telegram_message)
    @message.voice = @voice
  end

  private

  def initialize_user(telegram_message)
    telegram_chat_id = telegram_message.dig(:chat, :id)
    telegram_id = telegram_message.dig(:from, :id)
    first_name = telegram_message.dig(:from, :first_name)
    last_name = telegram_message.dig(:from, :last_name)
    username = telegram_message.dig(:from, :username)
    sender = User.find_by(telegram_id: telegram_id)
    if sender
      sender.username = username
      sender.telegram_chat_id = telegram_chat_id
    else
      sender = User.new(
        telegram_id: telegram_id,
        telegram_chat_id: telegram_chat_id,
        username: username,
        first_name: first_name,
        last_name: last_name
      )
    end
    sender
  end

  def initialize_unknown_content(telegram_message)
    @unknown_content = telegram_message.keys.any? { |key| UNKNOWN_CONTENT_KEYS.include?(key) }
  end

  def initialize_message(telegram_message)
    media_group_id = telegram_message['media_group_id']
    message = Message.find_by(telegram_media_group_id: media_group_id) if media_group_id
    message ||= Message.new(text: text, sender: sender, telegram_media_group_id: media_group_id)
    message.raw_data.attach(
      io: StringIO.new(JSON.generate(telegram_message)),
      filename: 'telegram_api.json',
      content_type: 'application/json'
    )
    message.unknown_content = unknown_content
    message
  end

  ## Each photo from the Telegram API is available in multiple resolutions,
  # we save only the largest (i.e. original) variant.
  def initialize_photos(telegram_message)
    return [] unless telegram_message[:photo]

    photo = Photo.new
    bot_token = "bot#{Telegram.bots[Rails.configuration.bot_id].token}"
    telegram_file = telegram_message[:photo].max { |a, b| a[:file_size] <=> b[:file_size] }
    file_id = telegram_file[:file_id]
    uri = URI("https://api.telegram.org/#{bot_token}/getFile")
    uri.query = URI.encode_www_form({ file_id: file_id })
    response = JSON.parse(URI.open(uri).read)
    file_path = response.dig('result', 'file_path')
    remote_file_location = URI("https://api.telegram.org/file/#{bot_token}/#{file_path}")
    photo.image.attach(io: URI.open(remote_file_location), filename: File.basename(remote_file_location.path))
    [photo]
  end

  def initialize_voice(telegram_message)
    return nil unless telegram_message[:voice]

    voice = Voice.new
    bot_token = "bot#{Telegram.bots[Rails.configuration.bot_id].token}"
    telegram_file = telegram_message[:voice]
    file_id = telegram_file[:file_id]
    uri = URI("https://api.telegram.org/#{bot_token}/getFile")
    uri.query = URI.encode_www_form({ file_id: file_id })
    response = JSON.parse(URI.open(uri).read)
    file_path = response.dig('result', 'file_path')
    remote_file_location = URI("https://api.telegram.org/file/#{bot_token}/#{file_path}")
    voice.attachment.attach(io: URI.open(remote_file_location), filename: File.basename(remote_file_location.path))
    voice
  end
end

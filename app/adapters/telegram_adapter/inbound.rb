# frozen_string_literal: true

module TelegramAdapter
  UNKNOWN_CONTRIBUTOR = :unknown_contributor
  UNKNOWN_CONTENT = :unknown_content
  CONNECT = :connect

  class Inbound
    UNKNOWN_CONTENT_KEYS = %w[
      animation audio document sticker video video_note
      contact dice game poll venue location
      invoice successful_payment passport_data
    ].freeze

    attr_reader :sender, :text, :message, :photos, :file

    def self.from(raw_data)
      new(JSON.parse(raw_data.download))
    end

    def initialize
      @callbacks = {}
    end

    def on(callback, &block)
      @callbacks[callback] = block
    end

    def consume(telegram_message)
      telegram_message = telegram_message.with_indifferent_access

      @text = telegram_message[:text] || telegram_message[:caption] || ''
      @sender = initialize_sender(telegram_message)
      return unless @sender

      @message = initialize_message(telegram_message)
      if telegram_message.keys.any? { |key| UNKNOWN_CONTENT_KEYS.include?(key) }
        @message.unknown_content = true
        trigger(UNKNOWN_CONTENT)
      end
      @photos = initialize_photos(telegram_message)
      @file = initialize_file(telegram_message)
      @message.file = @file
      @photos.each do |photo|
        @message.association(:photos).add_to_target(photo)
      end

      yield(@message) if block_given?
    end

    def avatar_url(contributor)
      return unless contributor.telegram_id

      profile_photos = Telegram.bot.get_user_profile_photos(user_id: contributor.telegram_id, limit: 1)
      largest_photo = profile_photos
                      .dig('result', 'photos', 0)
                      .max { |a, b| a['file_size'] <=> b['file_size'] }

      file = Telegram.bot.get_file(file_id: largest_photo['file_id'])
      file_path = file.dig('result', 'file_path')
      "https://api.telegram.org/file/bot#{Telegram.bot.token}/#{file_path}"
    end

    private

    def trigger(event, *args)
      return unless @callbacks.key?(event)

      @callbacks[event].call(*args)
    end

    def initialize_sender(telegram_message)
      telegram_id = telegram_message.dig(:from, :id)
      username = telegram_message.dig(:from, :username)
      sender = Contributor.find_by(telegram_id: telegram_id)
      if sender
        sender.username = username
        return sender
      end

      telegram_onboarding_token = text.delete_prefix('/start').strip.upcase
      sender = Contributor.find_by(telegram_id: nil, telegram_onboarding_token: telegram_onboarding_token)
      if sender
        sender.username = username
        sender.telegram_id = telegram_id
        trigger(CONNECT, sender)
        return sender
      end

      trigger(UNKNOWN_CONTRIBUTOR) and return nil
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
      message
    end

    ## Each photo from the Telegram API is available in multiple resolutions,
    # we save only the largest (i.e. original) variant.
    def initialize_photos(telegram_message)
      return [] unless telegram_message[:photo]

      telegram_file = telegram_message[:photo].max { |a, b| a[:file_size] <=> b[:file_size] }
      photo = Photo.new
      remote_file_location = retrieve_message_type_and_attach(telegram_file)
      photo.attachment.attach(io: remote_file_location.open, filename: File.basename(remote_file_location.path))
      [photo]
    end

    def initialize_file(telegram_message)
      return nil unless telegram_message[:voice]

      file = Message::File.new
      remote_file_location = retrieve_message_type_and_attach(telegram_message[:voice])
      file.attachment.attach(io: remote_file_location.open, filename: File.basename(remote_file_location.path))
      file
    end

    def retrieve_message_type_and_attach(telegram_file)
      bot_token = "bot#{Telegram.bot.token}"
      file_id = telegram_file[:file_id]
      uri = URI("https://api.telegram.org/#{bot_token}/getFile")
      uri.query = URI.encode_www_form({ file_id: file_id })
      response = JSON.parse(uri.open.read)
      file_path = response.dig('result', 'file_path')
      URI("https://api.telegram.org/file/#{bot_token}/#{file_path}")
    end
  end
end

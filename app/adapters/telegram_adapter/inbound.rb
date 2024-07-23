# frozen_string_literal: true

module TelegramAdapter
  UNKNOWN_CONTRIBUTOR = :unknown_contributor
  UNKNOWN_CONTENT = :unknown_content
  CONNECT = :connect
  UNSUBSCRIBE_CONTRIBUTOR = :unsubscribe_contributor
  RESUBSCRIBE_CONTRIBUTOR = :resubscribe_contributor

  class Inbound
    UNKNOWN_CONTENT_KEYS = %w[
      animation audio document sticker
      contact dice game poll venue location
      invoice successful_payment passport_data
    ].freeze

    attr_reader :sender, :text, :message, :photos, :file, :organization

    def initialize(organization)
      @organization = organization
      @callbacks = {}
    end

    def on(callback, &block)
      @callbacks[callback] = block
    end

    def consume(telegram_message)
      telegram_message = telegram_message.with_indifferent_access
      @text = telegram_message[:text] || telegram_message[:caption]
      @sender = initialize_sender(telegram_message)
      return unless @sender

      @sender.avatar_url = avatar_url(@sender) unless @sender.avatar.attached?
      @message = initialize_message(telegram_message)

      @photos = initialize_photos(telegram_message)
      @photos.each do |photo|
        @message.association(:photos).add_to_target(photo)
      end

      files = initialize_files(telegram_message)
      @message.files += files

      return unless create_message?

      yield(@message) if block_given?
    end

    private

    def avatar_url(contributor)
      return unless contributor.telegram_id

      profile_photos = organization.telegram_bot.get_user_profile_photos(user_id: contributor.telegram_id, limit: 1).with_indifferent_access
      first_photo = profile_photos.dig(:result, :photos, 0)
      return unless first_photo

      largest_size = first_photo.max { |a, b| a[:file_size] <=> b[:file_size] }
      file_url(largest_size)
    end

    def trigger(event, *args)
      return unless @callbacks.key?(event)

      @callbacks[event].call(*args)
    end

    def initialize_sender(telegram_message)
      telegram_id = telegram_message.dig(:from, :id)
      username = telegram_message.dig(:from, :username)
      sender = organization.contributors.find_by(telegram_id: telegram_id)
      if sender
        sender.username = username
        return sender
      end

      unless text
        trigger(UNKNOWN_CONTRIBUTOR)
        return nil
      end

      telegram_onboarding_token = text.delete_prefix('/start').strip.upcase
      sender = organization.contributors.find_by(telegram_id: nil, telegram_onboarding_token: telegram_onboarding_token)

      if sender
        sender.username = username
        sender.telegram_id = telegram_id
        trigger(CONNECT, sender)
        return sender
      end

      trigger(UNKNOWN_CONTRIBUTOR) and return nil
    end

    def initialize_message(telegram_message)
      trigger(UNSUBSCRIBE_CONTRIBUTOR, sender) if unsubscribe_text?(text)
      trigger(RESUBSCRIBE_CONTRIBUTOR, sender) if resubscribe_text?(text)

      media_group_id = telegram_message['media_group_id']
      message = Message.find_by(telegram_media_group_id: media_group_id) if media_group_id
      message ||= Message.new(text: text, sender: sender, telegram_media_group_id: media_group_id)
      message.raw_data.attach(
        io: StringIO.new(JSON.generate(telegram_message)),
        filename: 'telegram_api.json',
        content_type: 'application/json'
      )

      if telegram_message.keys.any? { |key| UNKNOWN_CONTENT_KEYS.include?(key) }
        message.unknown_content = true
        trigger(UNKNOWN_CONTENT)
      end

      message
    end

    ## Each photo from the Telegram API is available in multiple resolutions,
    # we save only the largest (i.e. original) variant.
    def initialize_photos(telegram_message)
      return [] unless telegram_message[:photo]

      telegram_file = telegram_message[:photo].max { |a, b| a[:file_size] <=> b[:file_size] }
      photo = Photo.new
      remote_file_location = file_url(telegram_file)
      photo.attachment.attach(io: remote_file_location.open, filename: File.basename(remote_file_location.path))
      [photo]
    end

    def initialize_files(telegram_message)
      return [] unless telegram_message[:voice] || telegram_message[:video]

      files = []
      files << initialize_file(telegram_message[:voice]) if telegram_message[:voice]
      files << initialize_file(telegram_message[:video]) if telegram_message[:video]
      files.compact
    end

    def initialize_file(telegram_file)
      file = Message::File.new
      remote_file_location = file_url(telegram_file)
      return unless remote_file_location

      file.attachment.attach(io: remote_file_location.open, filename: File.basename(remote_file_location.path))
      file
    end

    def file_url(telegram_file)
      file_size = telegram_file[:file_size]
      if file_size > 20_000_000
        exception = TelegramAdapter::FileTooLargeError.new(contributor_name: sender.name)
        ErrorNotifier.report(exception)
        nil
      else

        file = organization.telegram_bot.get_file(file_id: telegram_file[:file_id]).with_indifferent_access
        file_path = file.dig(:result, :file_path)
        URI("https://api.telegram.org/file/bot#{organization.telegram_bot.token}/#{file_path}")
      end
    end

    def unsubscribe_text?(text)
      text&.downcase&.strip.eql?(I18n.t('adapter.shared.unsubscribe.text'))
    end

    def resubscribe_text?(text)
      text&.downcase&.strip.eql?(I18n.t('adapter.shared.resubscribe.text'))
    end

    def create_message?
      has_non_text_content = photos.any? || message.files.any? || message.unknown_content
      text = message.text
      has_non_text_content || (text.present? && !unsubscribe_text?(text) && !resubscribe_text?(text))
    end
  end
end

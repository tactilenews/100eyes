# frozen_string_literal: true

module TelegramAdapter
  class Outbound
    class Photo < ApplicationJob
      queue_as :default
      discard_on Telegram::Bot::Forbidden do |job|
        message = job.arguments.first[:message]
        message&.update(blocked: true)
      end

      def perform(telegram_id:, media:, caption: nil)
        media_array = media.map.with_index do |photo, index|
          {
            type: 'photo',
            media: File.open(photo),
            caption: index.zero? ? caption : '',
          }
        end
        Telegram.bot.send_media_group(
          chat_id: telegram_id,
          media: media_array,
          parse_mode: :HTML
        )
      end
    end
  end
end

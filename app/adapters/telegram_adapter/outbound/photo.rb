module TelegramAdapter
  class Outbound 
    class Photo < ApplicationJob
      queue_as :default
      discard_on Telegram::Bot::Forbidden do |job|
        message = job.arguments.first[:message]
        message&.update(blocked: true)
      end

      def perform(telegram_id:, photo:, caption: nil)
        return unless telegram_id && photo

        Telegram.bot.send_photo(
          chat_id: telegram_id,
          photo: photo,
          caption: caption,
          parse_mode: :HTML
        )
      end
    end
  end
end

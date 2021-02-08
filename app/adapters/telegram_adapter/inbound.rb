# frozen_string_literal: true

module TelegramAdapter
  class Inbound
    def self.bounce!(chat)
      chat_id = chat && chat['id'] or raise 'Can not respond_with when chat is not present'
      Telegram.bot.send_message(
        chat_id: chat_id,
        text: Setting.telegram_contributor_not_found_message
      )
    end
  end
end

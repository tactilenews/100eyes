# frozen_string_literal: true

Rails.application.configure do
  config.after_initialize do
    Telegram.bots_config = {
      default: {
        token: Setting.telegram_bot_api_key,
        username: Setting.telegram_bot_username
      }
    }
  end
end

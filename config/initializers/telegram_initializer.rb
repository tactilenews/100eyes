# frozen_string_literal: true

Telegram.bots_config = {
  default: {
    token: ENV['TELEGRAM_BOT_API_KEY'],
    username: ENV['TELEGRAM_BOT_USERNAME']
  }
}

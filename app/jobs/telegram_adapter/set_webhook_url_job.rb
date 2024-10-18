# frozen_string_literal: true

module TelegramAdapter
  class SetWebhookUrlJob < ApplicationJob
    def perform(organization_id:)
      organization = Organization.find(organization_id)

      bot = Telegram::Bot::Client.new(organization.telegram_bot_api_key)
      path = "telegram/#{Telegram::Bot::RoutesHelper.token_hash(organization.telegram_bot_api_key)}"
      bot.set_webhook(url: "https://#{ENV.fetch('APPLICATION_HOSTNAME', 'localhost:3000')}/#{path}")
    end
  end
end

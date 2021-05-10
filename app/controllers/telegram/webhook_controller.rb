# frozen_string_literal: true

class Telegram::WebhookController < Telegram::Bot::UpdatesController
  def start!(_telegram_onboarding_token = nil)
    adapter = TelegramAdapter::Inbound.new

    adapter.on(TelegramAdapter::CONNECT, &:save!)

    adapter.on(TelegramAdapter::UNKNOWN_CONTRIBUTOR) do
      respond_with :message, text: Setting.telegram_contributor_not_found_message
    end

    adapter.consume(payload) do
      respond_with :message, text: Setting.telegram_welcome_message
    end
  end

  def message(msg)
    adapter = TelegramAdapter::Inbound.new

    contributor_connected = false

    adapter.on(TelegramAdapter::CONNECT) do |contributor|
      contributor.save!
      contributor_connected = true
      respond_with :message, text: Setting.telegram_welcome_message
    end

    adapter.on(TelegramAdapter::UNKNOWN_CONTENT) do
      respond_with :message, text: Setting.telegram_unknown_content_message
    end

    adapter.on(TelegramAdapter::UNKNOWN_CONTRIBUTOR) do
      respond_with :message, text: Setting.telegram_contributor_not_found_message
    end

    adapter.consume(msg) do |m|
      unless contributor_connected
        m.contributor.save!
        m.contributor.reply(adapter)
      end
    end
  end
end

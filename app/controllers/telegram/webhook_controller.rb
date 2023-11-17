# frozen_string_literal: true

class Telegram::WebhookController < Telegram::Bot::UpdatesController
  def start!(_telegram_onboarding_token = nil)
    adapter = TelegramAdapter::Inbound.new

    adapter.on(TelegramAdapter::CONNECT) do |contributor| # rubocop:disable Style/SymbolProc
      contributor.save!
    end

    adapter.on(TelegramAdapter::UNKNOWN_CONTRIBUTOR) do
      respond_with :message, text: Setting.telegram_contributor_not_found_message
    end

    adapter.consume(payload) do |m|
      m.contributor.send_welcome_message!
    end
  end

  def message(msg)
    adapter = TelegramAdapter::Inbound.new

    contributor_connected = false

    adapter.on(TelegramAdapter::CONNECT) do |contributor|
      contributor.save!
      contributor_connected = true
      contributor.send_welcome_message!
    end

    adapter.on(TelegramAdapter::UNKNOWN_CONTENT) do
      respond_with :message, text: Setting.telegram_unknown_content_message
    end

    adapter.on(TelegramAdapter::UNKNOWN_CONTRIBUTOR) do
      respond_with :message, text: Setting.telegram_contributor_not_found_message
    end

    adapter.on(TelegramAdapter::UNSUBSCRIBE_CONTRIBUTOR) do |contributor|
      UnsubscribeContributorJob.perform_later(contributor.id, TelegramAdapter::Outbound)
    end

    adapter.on(TelegramAdapter::RESUBSCRIBE_CONTRIBUTOR) do |contributor|
      ResubscribeContributorJob.perform_later(contributor.id, TelegramAdapter::Outbound)
    end

    adapter.consume(msg) do |m|
      unless contributor_connected
        m.contributor.save!
        m.contributor.reply(adapter)
      end
    end
  end
end

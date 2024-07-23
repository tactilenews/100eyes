# frozen_string_literal: true

class Telegram::WebhookController < Telegram::Bot::UpdatesController
  def organization
    Organization.find_by(telegram_bot_username: bot.username)
  end

  def start!(_telegram_onboarding_token = nil)
    adapter = TelegramAdapter::Inbound.new(organization)

    adapter.on(TelegramAdapter::CONNECT) do |contributor| # rubocop:disable Style/SymbolProc
      contributor.save!
    end

    adapter.on(TelegramAdapter::UNKNOWN_CONTRIBUTOR) do
      respond_with :message, text: organization.telegram_contributor_not_found_message
    end

    adapter.consume(payload) do |m|
      m.contributor.send_welcome_message!(organization)
    end
  end

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def message(msg)
    adapter = TelegramAdapter::Inbound.new(organization)

    contributor_connected = false

    adapter.on(TelegramAdapter::CONNECT) do |contributor|
      contributor.organization = organization
      contributor.save!
      contributor_connected = true
      contributor.send_welcome_message!(organization)
    end

    adapter.on(TelegramAdapter::UNKNOWN_CONTENT) do
      respond_with :message, text: organization.telegram_unknown_content_message
    end

    adapter.on(TelegramAdapter::UNKNOWN_CONTRIBUTOR) do
      respond_with :message, text: organization.telegram_contributor_not_found_message
    end

    adapter.on(TelegramAdapter::UNSUBSCRIBE_CONTRIBUTOR) do |contributor|
      UnsubscribeContributorJob.perform_later(organization.id, contributor.id, TelegramAdapter::Outbound)
    end

    adapter.on(TelegramAdapter::RESUBSCRIBE_CONTRIBUTOR) do |contributor|
      ResubscribeContributorJob.perform_later(organization.id, contributor.id, TelegramAdapter::Outbound)
    end

    adapter.consume(msg) do |m|
      unless contributor_connected
        m.contributor.save!
        m.contributor.reply(adapter)
      end
    end
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
end

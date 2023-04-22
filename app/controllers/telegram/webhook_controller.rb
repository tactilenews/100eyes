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
      handle_unsubscribe_contributor(contributor)
    end

    adapter.on(TelegramAdapter::SUBSCRIBE_CONTRIBUTOR) do |contributor|
      handle_subscribe_contributor(contributor)
    end

    adapter.consume(msg) do |m|
      unless contributor_connected
        m.contributor.save!
        m.contributor.reply(adapter)
      end
    end
  end

  private

  def handle_unsubscribe_contributor(contributor)
    contributor.update!(deactivated_at: Time.current)
    TelegramAdapter::Outbound.send_unsubsribed_successfully_message!(contributor)
    ContributorMarkedInactive.with(contributor_id: contributor.id).deliver_later(User.all)
    User.admin.find_each do |admin|
      PostmarkAdapter::Outbound.contributor_marked_as_inactive!(admin, contributor)
    end
  end

  def handle_subscribe_contributor(contributor)
    contributor.update!(deactivated_at: nil)
    TelegramAdapter::Outbound.send_welcome_message!(contributor)
    ContributorSubscribed.with(contributor_id: contributor.id).deliver_later(User.all)
    User.admin.find_each do |admin|
      PostmarkAdapter::Outbound.contributor_subscribed!(admin, contributor)
    end
  end
end

# frozen_string_literal: true

require 'openssl'

class Threema::WebhookController < ApplicationController
  skip_before_action :require_login, :verify_authenticity_token

  def message
    adapter = ThreemaAdapter::Inbound.new

    adapter.on(ThreemaAdapter::UNKNOWN_CONTRIBUTOR) do |threema_id|
      handle_unknown_contributor(threema_id)
    end

    adapter.on(ThreemaAdapter::UNSUPPORTED_CONTENT) do |contributor|
      ThreemaAdapter::Outbound.send_unsupported_content_message!(contributor)
    end

    adapter.on(ThreemaAdapter::UNSUBSCRIBE_CONTRIBUTOR) do |contributor|
      handle_unsubscribe_contributor(contributor)
    end

    adapter.on(ThreemaAdapter::SUBSCRIBE_CONTRIBUTOR) do |contributor|
      handle_subscribe_contributor(contributor)
    end

    adapter.consume(threema_webhook_params) do |message|
      message.contributor.reply(adapter)
    end

    head :ok
  rescue ActiveRecord::RecordInvalid
    head :service_unavailable
  end

  private

  def threema_webhook_params
    params.permit(:from, :to, :messageId, :date, :nonce, :box, :mac, :nickname)
  end

  def handle_unknown_contributor(threema_id)
    exception = ThreemaAdapter::UnknownContributorError.new(threema_id: threema_id)
    ErrorNotifier.report(exception)
  end

  def handle_unsubscribe_contributor(contributor)
    contributor.update!(unsubscribed_at: Time.current)
    ThreemaAdapter::Outbound.send_unsubsribed_successfully_message!(contributor)
    ContributorMarkedInactive.with(contributor_id: contributor.id).deliver_later(User.all)
    User.admin.find_each do |admin|
      PostmarkAdapter::Outbound.contributor_marked_as_inactive!(admin, contributor)
    end
  end

  def handle_subscribe_contributor(contributor)
    if contributor.deactivated_by_user.present?
      exception = StandardError.new(
        "Contributor #{contributor.name} has been deactivated by #{contributor.deactivated_by_user.name} and has tried to re-subscribe"
      )
      ErrorNotifier.report(exception)
      return
    end

    contributor.update!(unsubscribed_at: nil)
    ThreemaAdapter::Outbound.send_welcome_message!(contributor)
    ContributorSubscribed.with(contributor_id: contributor.id).deliver_later(User.all)
    User.admin.find_each do |admin|
      PostmarkAdapter::Outbound.contributor_subscribed!(admin, contributor)
    end
  end
end

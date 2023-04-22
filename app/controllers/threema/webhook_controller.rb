# frozen_string_literal: true

require 'openssl'

class Threema::WebhookController < ApplicationController
  skip_before_action :require_login, :verify_authenticity_token

  def message
    adapter = ThreemaAdapter::Inbound.new

    adapter.on(ThreemaAdapter::DELIVERY_RECEIPT_RECEIVED) do
      return head :ok
    end

    adapter.on(ThreemaAdapter::UNKNOWN_CONTRIBUTOR) do |threema_id|
      handle_unknown_contributor(threema_id)
      return head :ok
    end

    adapter.on(ThreemaAdapter::UNSUPPORTED_CONTENT) do |contributor|
      ThreemaAdapter::Outbound.send_unsupported_content_message!(contributor)
    end

    adapter.on(ThreemaAdapter::UNSUBSCRIBE_CONTRIBUTOR) do |contributor|
      handle_unsubsribe_contributor(contributor)
      return head :ok
    end

    adapter.consume(threema_webhook_params) do |message|
      message.contributor.reply(adapter)
      return head :ok
    end
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

  def handle_unsubsribe_contributor(contributor)
    contributor.update!(deactivated_at: Time.current)
    ThreemaAdapter::Outbound.send_unsubsribed_successfully_message!(contributor)
    ContributorMarkedInactive.with(contributor_id: contributor.id).deliver_later(User.all)
    User.admin.find_each do |admin|
      PostmarkAdapter::Outbound.contributor_marked_as_inactive!(admin, contributor)
    end
  end
end

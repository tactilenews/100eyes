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
      UnsubscribeContributorJob.perform_later(contributor.id, ThreemaAdapter::Outbound)
    end

    adapter.on(ThreemaAdapter::RESUBSCRIBE_CONTRIBUTOR) do |contributor|
      ResubscribeContributorJob.perform_later(contributor.id, ThreemaAdapter::Outbound)
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
end

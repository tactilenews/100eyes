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
end

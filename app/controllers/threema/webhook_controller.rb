# frozen_string_literal: true

require 'openssl'

class Threema::WebhookController < ApplicationController
  skip_before_action :require_login, :verify_authenticity_token

  def message
    threema_message = ThreemaAdapter::Inbound.new(threema_webhook_params)
    return head :ok if threema_message.delivery_receipt

    contributor = threema_message.sender
    return head :ok unless contributor

    if threema_message.unknown_content
      ThreemaAdapter::Inbound.bounce!(recipient: contributor,
                                      text: Setting.threema_unknown_content_message)
    end

    head :ok if contributor.reply(threema_message)
  rescue ActiveRecord::RecordInvalid
    head :service_unavailable
  end

  private

  def threema_webhook_params
    params.permit(:from, :to, :messageId, :date, :nonce, :box, :mac, :nickname)
  end
end

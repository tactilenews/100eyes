# frozen_string_literal: true

require 'openssl'

class Threema::WebhookController < ApplicationController
  skip_before_action :require_login, :verify_authenticity_token

  def message
    threema_message = ThreemaMessage.new(threema_webhook_params)

    return head :ok if threema_message.delivery_receipt

    contributor = threema_message.sender
    # Open question: How would this look?
    # Would we have this use case? Should we respond with
    # a message and 200 to avoid retries?
    return unless contributor

    if threema_message.unknown_content
      respond_to_unknown_content_and_prevent_retries(contributor)
      return
    end

    head :ok if contributor.reply(threema_message)
  rescue ActiveRecord::RecordInvalid
    head :service_unavailable
  end

  private

  def threema_webhook_params
    params.permit(:from, :to, :messageId, :date, :nonce, :box, :mac, :nickname)
  end

  def respond_to_unknown_content_and_prevent_retries(contributor)
    ThreemaAdapter.new(message: Message.new(text: Setting.telegram_unknown_content_message, recipient: contributor)).send!
    head :ok
  end
end

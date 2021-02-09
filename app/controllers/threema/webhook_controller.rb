# frozen_string_literal: true

require 'openssl'

class Threema::WebhookController < ApplicationController
  protect_from_forgery with: :null_session
  skip_before_action :require_login

  def message
    threema_message = ThreemaMessage.new(threema_webhook_params)
    contributor = threema_message.sender

    return unless contributor

    if contributor.reply(threema_message)
      head :ok
    else
      head :service_unavailable
    end
  end

  private

  def threema_webhook_params
    params.permit(:from, :to, :messageId, :date, :nonce, :box, :mac, :nickname)
  end
end

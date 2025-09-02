# frozen_string_literal: true

class Signal::WebhookController < ApplicationController
  skip_before_action :require_login, :verify_authenticity_token, :user_permitted?, :set_organization

  def message
    signal_message = signal_webhook_params.to_h.with_indifferent_access[:params]
    SignalAdapter::ProcessWebhookJob.perform_later(signal_message: signal_message)

    head :ok
  end

  private

  def signal_webhook_params
    raw_message = params.permit(:jsonrpc, :method, params: {}, webhook: {})
  end
end

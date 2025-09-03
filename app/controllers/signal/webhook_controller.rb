# frozen_string_literal: true

module Signal
  class WebhookController < ApplicationController
    skip_before_action :require_login, :verify_authenticity_token, :user_permitted?, :set_organization

    def message
      # Parse raw JSON body to discriminate JSON-RPC responses from 'receive' notifications.
      begin
        raw = request.raw_post
        payload = raw&.length&.positive? ? JSON.parse(raw) : {}
      rescue StandardError
        payload = {}
      end

      # Only handle notifications with method 'receive' and params present. Ignore other JSON-RPC messages (e.g. responses to listAccounts).
      if payload.is_a?(Hash) && payload['method'] == 'receive' && payload['params'].present?
        signal_message = payload['params'].with_indifferent_access
        SignalAdapter::ProcessWebhookJob.perform_later(signal_message: signal_message)
      end

      head :ok
    end

    private

    def signal_webhook_params
      params.permit(:jsonrpc, :method, params: {}, webhook: {})
    end
  end
end

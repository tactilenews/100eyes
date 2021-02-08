# frozen_string_literal: true

require 'openssl'

class Threema::WebhookController < ApplicationController
  protect_from_forgery with: :null_session
  skip_before_action :require_login
  before_action :verify_threema_authentication_and_integrity

  def message
    head :ok
  end

  private

  def threema_webhook_params
    params.permit(:from, :to, :messageId, :date, :nonce, :box, :mac, :nickname)
  end

  def verify_threema_authentication_and_integrity
    auth_data = threema_webhook_params.slice(:from, :to, :messageId, :date, :nonce, :box, :nickname)
    check_string = auth_data.to_unsafe_h.map { |k, v| "#{k}=#{v}" }.sort.join("\n")
    secret_key = OpenSSL::Digest.new('SHA256').digest(ENV['THREEMARB_API_SECRET'])
    valid_hash = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), secret_key, check_string)

    binding.pry
    raise ActionController::BadRequest unless valid_hash.casecmp(threema_webhook_params[:mac]).zero?
  end
end

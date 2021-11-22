# frozen_string_literal: true

require 'openssl'

class InvitesController < ApplicationController
  def create
    payload = { invite_code: SecureRandom.base64(16), action: 'onboarding' }
    jwt = create_jwt(payload)
    render json: { url: onboarding_url(jwt: jwt) }
  end

  private

  def create_jwt(payload, expires_in: 1.year.from_now.to_i)
    JsonWebToken.encode(payload, expires_in: expires_in)
  end
end

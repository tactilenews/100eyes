# frozen_string_literal: true

require 'openssl'

class InvitesController < ApplicationController
  include JwtHelper

  def create
    payload = { invite_code: SecureRandom.base64(16), action: 'onboarding' }
    jwt = create_jwt(payload)
    render json: { url: organization_onboarding_url(@organization, jwt: jwt) }
  end
end

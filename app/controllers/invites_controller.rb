# frozen_string_literal: true

require 'openssl'

class InvitesController < ApplicationController
  include JwtHelper

  def create
    organization = current_user.admin? ? Organization.last : current_user.organization
    payload = { invite_code: SecureRandom.base64(16), action: 'onboarding', organization_id: organization.id }
    jwt = create_jwt(payload)
    render json: { url: onboarding_url(jwt: jwt) }
  end
end

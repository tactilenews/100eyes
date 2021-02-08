# frozen_string_literal: true

require 'openssl'

class OnboardingController < ApplicationController
  include JwtHelper

  skip_before_action :require_login, except: :create_invite_url
  before_action -> { verify_onboarding_jwt(jwt_param) }, except: %i[create_invite_url success]

  layout 'onboarding'

  def index
    @jwt = jwt_param
    @contributor = Contributor.new
  end

  def success; end

  def create_invite_url
    payload = { invite_code: SecureRandom.base64(16), action: 'onboarding' }
    jwt = create_jwt(payload)
    render json: { url: onboarding_url(jwt: jwt) }
  end

  private

  def jwt_param
    params.require(:jwt)
  end
end

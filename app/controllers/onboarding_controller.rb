# frozen_string_literal: true

require 'openssl'

class OnboardingController < ApplicationController
  skip_before_action :require_login, except: :create_invite_url
  before_action :verify_onboarding_jwt, except: %i[create_invite_url success]

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

  def verify_onboarding_jwt
    invalidated_jwt = JsonWebToken.where(invalidated_jwt: jwt_param)
    raise ActionController::BadRequest if invalidated_jwt.exists?

    decoded_token = JsonWebToken.decode(jwt_param)

    raise ActionController::BadRequest if decoded_token.first['data']['action'] != 'onboarding'
  rescue StandardError
    render :unauthorized, status: :unauthorized
  end

  def jwt_param
    params.require(:jwt)
  end

  def create_jwt(payload, expires_in: 48.hours.from_now.to_i)
    JsonWebToken.encode(payload, expires_in: expires_in)
  end

end

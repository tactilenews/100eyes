# frozen_string_literal: true

module JwtHelper
  def create_jwt(payload, expires_in: 48.hours.from_now.to_i)
    JsonWebToken.encode(payload, expires_in: expires_in)
  end

  def invalidate_jwt(jwt)
    JsonWebToken.create(invalidated_jwt: jwt)
  end

  def verify_onboarding_jwt(jwt)
    invalidated_jwt = JsonWebToken.where(invalidated_jwt: jwt)
    raise ActionController::BadRequest if invalidated_jwt.exists?

    decoded_token = JsonWebToken.decode(jwt)

    raise ActionController::BadRequest if decoded_token.first['data']['action'] != 'onboarding'
  rescue StandardError
    render 'onboarding/unauthorized', status: :unauthorized
  end
end

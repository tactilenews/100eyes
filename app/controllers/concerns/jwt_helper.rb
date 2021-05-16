# frozen_string_literal: true

module JwtHelper
  def create_jwt(payload, expires_in: 48.hours.from_now.to_i)
    JsonWebToken.encode(payload, expires_in: expires_in)
  end
end

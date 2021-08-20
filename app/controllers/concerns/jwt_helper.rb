# frozen_string_literal: true

module JwtHelper
  def create_jwt(payload, expires_in: 7.days.from_now.to_i)
    JsonWebToken.encode(payload, expires_in: expires_in)
  end
end

# frozen_string_literal: true

class JsonWebToken < ApplicationRecord
  SECRET_KEY = Rails.application.secrets.secret_key_base.to_s

  def self.encode(payload, expires_in: 48.hours.from_now.to_i)
    expires_in_payload = { data: payload, expires_in: expires_in }
    JWT.encode(expires_in_payload, SECRET_KEY, 'HS256')
  end

  def self.decode(token)
    JWT.decode(token, SECRET_KEY, true, { algorithm: 'HS256' })
  end
end

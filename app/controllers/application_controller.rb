# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :authenticate

  private

  def authenticate
    return if Rails.env.development?

    http_basic_authenticate_or_request_with(
      name: ENV['BASIC_AUTH_LOGIN_USER'],
      password: ENV['BASIC_AUTH_LOGIN_PASSWORD']
    )
  end
end

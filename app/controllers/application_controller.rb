# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :authenticate

  private

  def authenticate
    return if Rails.env.development?

    http_basic_authenticate_or_request_with(
      name: Rails.application.credentials.login.dig(:user),
      password: Rails.application.credentials.login.dig(:password)
    )
  end
end

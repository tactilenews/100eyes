# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :authenticate

  private

  def authenticate
    return if Rails.env.development?

    http_basic_authenticate_or_request_with(
      name: Setting.basic_auth_login_user,
      password: Setting.basic_auth_login_password
    )
  end
end

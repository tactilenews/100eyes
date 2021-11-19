# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Clearance::Controller

  before_action :require_login, :ensure_otp_setup
  before_action :ensure_otp_verified

  private

  def sign_out
    super

    session.delete(:otp_verified_for_user)
  end

  def ensure_otp_verified
    return if signed_out? || !current_user.otp_enabled?

    redirect_to new_otp_confirmation_path if session[:otp_verified_for_user] != current_user.id
  end

  def ensure_otp_setup
    return if signed_out? || current_user.otp_enabled?

    redirect_to two_factor_auth_setup_user_setting_path(current_user)
  end
end

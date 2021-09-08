# frozen_string_literal: true

module Authentication
  extend ActiveSupport::Concern
  include Clearance::Controller

  included do
    before_action :require_login
    before_action :ensure_otp_is_set_up
    before_action :ensure_otp_is_verified
  end

  private

  def sign_out
    super

    session.delete(:otp_verified_for_user)
  end

  def ensure_otp_is_verified
    return if signed_out? || !current_user.otp_enabled?

    redirect_to new_otp_confirmation_path if session[:otp_verified_for_user] != current_user.id
  end

  def ensure_otp_is_set_up
    return if signed_out? || current_user.otp_enabled?

    redirect_to new_otp_setup_path
  end
end

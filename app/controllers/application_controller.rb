# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Clearance::Controller
  before_action :require_login, :ensure_2fa_setup
  around_action :use_locale

  private

  def use_locale(&action)
    locale = locale_params[:locale] || I18n.default_locale
    I18n.with_locale(locale, &action)
  end

  def default_url_options(options = {})
    return options.merge(locale: I18n.locale) unless I18n.locale == I18n.default_locale

    options
  end

  def locale_params
    params.permit(:locale)
  end

  def ensure_2fa_setup
    return if signed_out? || current_user.otp_enabled?

    redirect_to two_factor_auth_setup_user_setting_path(current_user)
  end

  def create_session
    sign_in(@user) do |status|
      if status.success?
        redirect_back_or dashboard_path
      else
        redirect_to sign_in_path, flash: { alert: I18n.t('flashes.failure_when_not_signed_in') }
      end
    end
  end
end

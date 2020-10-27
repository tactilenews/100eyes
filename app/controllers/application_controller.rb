# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :authenticate
  around_action :use_locale

  private

  def authenticate
    return if Rails.env.development?

    http_basic_authenticate_or_request_with(
      name: ENV['BASIC_AUTH_LOGIN_USER'],
      password: ENV['BASIC_AUTH_LOGIN_PASSWORD']
    )
  end

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
end

# frozen_string_literal: true

Clearance.configure do |config|
  config.allow_sign_up = false
  config.cookie_domain = ->(request) { request.host }
  config.cookie_expiration = ->(_cookies) { 1.day.from_now }
  config.secure_cookie = true if Rails.env.production?
  config.mailer_sender = ENV['EMAIL_FROM_ADDRESS']
  config.rotate_csrf_on_sign_in = true
  config.same_site = :lax
  config.redirect_url = '/dashboard'
  config.routes = false
  config.sign_in_on_password_reset = false

  Rails.application.config.to_prepare do
    Clearance::BaseController.layout 'minimal'
  end
end

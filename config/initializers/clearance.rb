# frozen_string_literal: true

Clearance.configure do |config|
  config.allow_sign_up = false
  config.cookie_domain = ->(request) { request.host }
  config.cookie_expiration = ->(_cookies) { 1.day.from_now }
  config.secure_cookie = true if Rails.env.production?
  config.mailer_sender = Setting.email_from_address
  config.rotate_csrf_on_sign_in = true
  config.same_site = :lax
  config.redirect_url = '/dashboard'
  config.routes = false

  Rails.application.config.to_prepare do
    Clearance::PasswordsController.layout 'clearance'
    Clearance::SessionsController.layout 'clearance'
  end
end

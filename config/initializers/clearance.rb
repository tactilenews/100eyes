# frozen_string_literal: true

Clearance.configure do |config|
  config.allow_sign_up = false
  config.cookie_domain = ->(request) { request.host }
  config.cookie_expiration = ->(_cookies) { 1.day.from_now }
  config.secure_cookie = true
  config.sign_in_guards = ['Clearance::EmailConfirmationGuard']
  config.mailer_sender = Setting.email_from_address
  config.rotate_csrf_on_sign_in = true

  Rails.application.config.to_prepare do
    Clearance::PasswordsController.layout 'clearance'
    Clearance::SessionsController.layout 'clearance'
  end
end

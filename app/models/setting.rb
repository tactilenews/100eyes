# frozen_string_literal: true

# RailsSettings Model
class Setting < RailsSettings::Base
  cache_prefix { 'v1' }

  field :project_name, default: ENV['HUNDRED_EYES_PROJECT_NAME'] || '100eyes'

  field :onboarding_token, default: ENV['ONBOARDING_TOKEN'] || 'abcd1234'
  field :onboarding_logo, default: '/onboarding/logo.png'
  field :onboarding_hero, default: '/onboarding/hero.jpg'
  field :onboarding_title, default: 'Hallo und herzlich willkommen beim 100eyes!'
  field :onboarding_page, default: File.read(File.join('config', 'locales', 'onboarding', 'page.md'))
  field :onboarding_success_heading, default: File.read(File.join('config', 'locales', 'onboarding', 'success_heading.txt'))
  field :onboarding_success_text, default: File.read(File.join('config', 'locales', 'onboarding', 'success_text.txt'))
  field :onboarding_unauthorized_heading,
        default: File.read(File.join('config', 'locales', 'onboarding', 'unauthorized_heading.txt'))
  field :onboarding_unauthorized_text, default: File.read(File.join('config', 'locales', 'onboarding', 'unauthorized_text.txt'))

  field :telegram_welcome_message, default: File.read(File.join('config', 'locales', 'telegram', 'welcome.txt'))
  field :telegram_unknown_content_message, default: File.read(File.join('config', 'locales', 'telegram', 'unknown_content.txt'))

  field :application_host, readonly: true, default: ENV['APPLICATION_HOST'] || 'http://localhost:3000'
  field :telegram_bot_api_key, readonly: true, default: ENV['TELEGRAM_BOT_API_KEY']
  field :telegram_bot_username, readonly: true, default: ENV['TELEGRAM_BOT_USERNAME']
  field :sendgrid_username, readonly: true, default: ENV['SENDGRID_USERNAME'] || 'apikey'
  field :sendgrid_password, readonly: true, default: ENV['SENDGRID_PASSWORD']
  field :sendgrid_domain, readonly: true, default: ENV['SENDGRID_DOMAIN']
  field :sendgrid_from, readonly: true, default: ENV['SENDGRID_FROM']
  field :inbound_email_password, readonly: true, default: ENV['RAILS_INBOUND_EMAIL_PASSWORD']

  field :basic_auth_login_user, readonly: true, default: ENV['BASIC_AUTH_LOGIN_USER']
  field :basic_auth_login_password, readonly: true, default: ENV['BASIC_AUTH_LOGIN_PASSWORD']

  field :mailserver_host, readonly: true, default: ENV['MAILSERVER_HOST'] || 'localhost'
  field :mailserver_port, readonly: true, default: ENV['MAILSERVER_PORT'] || 1025
end

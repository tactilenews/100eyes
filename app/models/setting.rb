# frozen_string_literal: true

# RailsSettings Model
class Setting < RailsSettings::Base
  cache_prefix { 'v1' }

  field :project_name, default: ENV['HUNDRED_EYES_PROJECT_NAME'] || '100eyes'
  field :application_host, readonly: true, default: ENV['APPLICATION_HOSTNAME'] || 'localhost:3000'

  field :onboarding_logo, default: '/onboarding/logo.png'
  field :onboarding_hero, default: '/onboarding/hero.jpg'
  field :onboarding_title, default: 'Hallo und herzlich willkommen beim 100eyes!'
  field :onboarding_page, default: File.read(File.join('config', 'locales', 'onboarding', 'page.md'))
  field :onboarding_success_heading, default: File.read(File.join('config', 'locales', 'onboarding', 'success_heading.txt'))
  field :onboarding_success_text, default: File.read(File.join('config', 'locales', 'onboarding', 'success_text.txt'))
  field :onboarding_unauthorized_heading,
        default: File.read(File.join('config', 'locales', 'onboarding', 'unauthorized_heading.txt'))
  field :onboarding_unauthorized_text, default: File.read(File.join('config', 'locales', 'onboarding', 'unauthorized_text.txt'))

  field :telegram_unknown_content_message, default: File.read(File.join('config', 'locales', 'telegram', 'unknown_content.txt'))
  field :telegram_contributor_not_found_message, default: File.read(File.join('config', 'locales', 'telegram', 'who_are_you.txt'))

  field :telegram_bot_api_key, readonly: true, default: ENV['TELEGRAM_BOT_API_KEY']
  field :telegram_bot_username, readonly: true, default: ENV['TELEGRAM_BOT_USERNAME']

  field :inbound_email_password, readonly: true, default: ENV['RAILS_INBOUND_EMAIL_PASSWORD']
  field :email_from_address, readonly: true, default: ENV['EMAIL_FROM_ADDRESS']
  field :postmark_api_token, readonly: true, default: ENV['POSTMARK_API_TOKEN']
  field :postmark_broadcasts_stream, readonly: true, default: ENV['POSTMARK_BROADCASTS_STREAM'] || 'broadcasts'
  field :postmark_transactional_stream, readonly: true, default: ENV['POSTMARK_TRANSACTIONAL_STREAM'] || 'outbound'

  field :basic_auth_login_user, readonly: true, default: ENV['BASIC_AUTH_LOGIN_USER']
  field :basic_auth_login_password, readonly: true, default: ENV['BASIC_AUTH_LOGIN_PASSWORD']

  field :mailserver_host, readonly: true, default: ENV['MAILSERVER_HOST'] || 'localhost'
  field :mailserver_port, readonly: true, default: ENV['MAILSERVER_PORT'] || 1025
end

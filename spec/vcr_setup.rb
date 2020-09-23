# frozen_string_literal: true

require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'vcr_cassettes'
  c.hook_into :webmock
  c.filter_sensitive_data('<TELEGRAM_BOT_API_KEY>') { Telegram.bots[Rails.configuration.bot_id].token }
  c.filter_sensitive_data('<FACEBOOK_ACCESS_TOKEN>') { Rails.application.credentials.dig(:facebook, :access_token) }
  c.filter_sensitive_data('<FACEBOOK_VERIFY_TOKEN>') { Rails.application.credentials.dig(:facebook, :verify_token) }
  c.filter_sensitive_data('<FACEBOOK_APP_SECRET>') { Rails.application.credentials.dig(:facebook, :app_secret) }
  c.configure_rspec_metadata!
end

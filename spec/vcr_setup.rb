# frozen_string_literal: true

require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'vcr_cassettes'
  c.hook_into :webmock
  c.filter_sensitive_data('TELEGRAM_BOT_API_KEY') { Setting.telegram_bot_api_key }
  c.filter_sensitive_data('TELEGRAM_BOT_USERNAME') { Setting.telegram_bot_username }
  c.filter_sensitive_data('*100EYES') { Setting.threemarb_api_identity }
  c.filter_sensitive_data('THREEMARB_API_SECRET') { ENV.fetch('THREEMARB_API_SECRET', nil) }
  c.filter_sensitive_data('THREEMARB_PRIVATE') { ENV.fetch('THREEMARB_PRIVATE', nil) }
  c.filter_sensitive_data('SIGNAL_SERVER_PHONE_NUMBER') { Setting.signal_server_phone_number }

  c.configure_rspec_metadata!

  # Capybara.server_host default
  c.ignore_hosts '0.0.0.0', 'chrome', '127.0.0.1'
end

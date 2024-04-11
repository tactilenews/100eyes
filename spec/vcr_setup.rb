# frozen_string_literal: true

require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'vcr_cassettes'
  c.hook_into :webmock
  c.filter_sensitive_data('TELEGRAM_BOT_API_KEY') { ENV.fetch('TELEGRAM_BOT_API_KEY', nil) }
  c.filter_sensitive_data('TELEGRAM_BOT_USERNAME') { ENV.fetch('TELEGRAM_BOT_USERNAME', nil) }
  c.filter_sensitive_data('*100EYES') { ENV.fetch('THREEMARB_API_IDENTITY', nil) }
  c.filter_sensitive_data('THREEMARB_API_SECRET') { ENV.fetch('THREEMARB_API_SECRET', nil) }
  c.filter_sensitive_data('THREEMARB_PRIVATE') { ENV.fetch('THREEMARB_PRIVATE', nil) }
  c.filter_sensitive_data('SIGNAL_SERVER_PHONE_NUMBER') { Setting.signal_server_phone_number }

  c.configure_rspec_metadata!

  # Capybara.server_host default
  c.ignore_hosts '0.0.0.0', 'chrome', '127.0.0.1'
end

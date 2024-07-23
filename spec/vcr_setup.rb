# frozen_string_literal: true

require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'vcr_cassettes'
  c.hook_into :webmock
  c.filter_sensitive_data('TELEGRAM_BOT_API_KEY') { 'TELEGRAM_BOT_API_KEY' }
  c.filter_sensitive_data('TELEGRAM_BOT_USERNAME') { 'TELEGRAM_BOT_USERNAME' }
  c.filter_sensitive_data('SIGNAL_SERVER_PHONE_NUMBER') { '+4912345678' }

  c.configure_rspec_metadata!

  # Capybara.server_host default
  c.ignore_hosts '0.0.0.0', 'chrome', '127.0.0.1'
end

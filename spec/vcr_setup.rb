# frozen_string_literal: true

require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'vcr_cassettes'
  c.hook_into :webmock
  c.filter_sensitive_data('TELEGRAM_BOT_API_KEY') { ENV['TELEGRAM_BOT_API_KEY'] }
  c.filter_sensitive_data('TELEGRAM_BOT_USERNAME') { ENV['TELEGRAM_BOT_USERNAME'] }
  c.filter_sensitive_data('*100EYES') { ENV['THREEMARB_API_IDENTITY'] }
  c.filter_sensitive_data('THREEMARB_API_SECRET') { ENV['THREEMARB_API_SECRET'] }
  c.filter_sensitive_data('THREEMARB_PRIVATE') { ENV['THREEMARB_PRIVATE'] }
  c.filter_sensitive_data('SIGNAL_SERVER_PHONE_NUMBER') { ENV['SIGNAL_SERVER_PHONE_NUMBER'] }

  c.configure_rspec_metadata!

  # Capybara.server_host default
  c.ignore_hosts '127.0.0.1'
end

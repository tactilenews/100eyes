# frozen_string_literal: true

require 'vcr'
require 'webdrivers'

driver_hosts = Webdrivers::Common.subclasses.map { |driver| URI(driver.base_url).host }

VCR.configure do |c|
  c.cassette_library_dir = 'vcr_cassettes'
  c.hook_into :webmock
  c.filter_sensitive_data('<TELEGRAM_BOT_API_KEY>') { Telegram.bot.token }
  c.filter_sensitive_data('<TELEGRAM_BOT_USERNAME>') { Telegram.bot.username }
  c.configure_rspec_metadata!
  c.ignore_localhost = true
  c.ignore_hosts(*driver_hosts)
end

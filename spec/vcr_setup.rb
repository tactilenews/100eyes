# frozen_string_literal: true

require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'vcr_cassettes'
  c.hook_into :webmock
  c.filter_sensitive_data('<TELEGRAM_BOT_API_KEY>') { Telegram.bot.token }
  c.filter_sensitive_data('<TELEGRAM_BOT_USERNAME>') { Telegram.bot.username }
  c.configure_rspec_metadata!
end

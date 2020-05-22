# frozen_string_literal: true

require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'vcr_cassettes'
  c.hook_into :webmock
  c.filter_sensitive_data('<TELEGRAM_BOT_API_KEY>') { Rails.application.credentials.dig(:telegram, :bots, Rails.configuration.bot_id) }
end

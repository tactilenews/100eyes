# frozen_string_literal: true

require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'vcr_cassettes'
  c.hook_into :webmock
  c.filter_sensitive_data('TELEGRAM_BOT_API_KEY') { 'TELEGRAM_BOT_API_KEY' }
  c.filter_sensitive_data('TELEGRAM_BOT_USERNAME') { 'TELEGRAM_BOT_USERNAME' }
  c.filter_sensitive_data('SIGNAL_SERVER_PHONE_NUMBER') { '+4912345678' }
  c.filter_sensitive_data('D360-API-KEY') do |interaction|
    interaction.request.headers['D360-Api-Key'].try(:first)
  end
  c.filter_sensitive_data('THREE_SIXTY_DIALOG_PARTNER_PASSWORD') do
    ENV['THREE_SIXTY_DIALOG_PARTNER_PASSWORD']
  end
  c.filter_sensitive_data('THREE_SIXTY_DIALOG_PARTNER_USERNAME') do
    ENV['THREE_SIXTY_DIALOG_PARTNER_USERNAME']
  end
  c.filter_sensitive_data('THREE_SIXTY_DIALOG_PARTNER_ID') do
    ENV['THREE_SIXTY_DIALOG_PARTNER_ID']
  end
  c.filter_sensitive_data('Bearer <TOKEN>') do |interaction|
    interaction.request.headers['Authorization'].try(:first)
  end
  c.filter_sensitive_data('THREE_SIXTY_DIALOG_CLIENT_WABA_ACCOUNT_ID') { 'valid_waba_account_id' }
  c.configure_rspec_metadata!

  # Capybara.server_host default
  c.ignore_hosts '0.0.0.0', 'chrome', '127.0.0.1'
end

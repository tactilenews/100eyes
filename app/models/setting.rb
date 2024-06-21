# frozen_string_literal: true

# RailsSettings Model
class Setting < RailsSettings::Base
  cache_prefix { 'v1' }

  field :application_host, readonly: true, default: ENV['APPLICATION_HOSTNAME'] || 'localhost:3000'

  field :git_commit_sha, readonly: true, default: ENV.fetch('GIT_COMMIT_SHA', nil)
  field :git_commit_date, readonly: true, default: ENV.fetch('GIT_COMMIT_DATE', nil)

  field :signal_monitoring_url, readonly: true, default: ENV.fetch('SIGNAL_MONITORING_URL', nil)
  field :signal_cli_rest_api_endpoint, readonly: true, default: ENV['SIGNAL_CLI_REST_API_ENDPOINT'] || 'http://localhost:8080'
  field :signal_cli_rest_api_attachment_path, readonly: true,
                                              default: ENV['SIGNAL_CLI_REST_API_ATTACHMENT_PATH'] || 'signal-cli-config/attachments/'

  field :twilio_account_sid, readonly: true, default: ENV.fetch('TWILIO_ACCOUNT_SID', nil)

  field :three_sixty_dialog_partner_token, default: ''
  field :three_sixty_dialog_partner_id, readonly: true, default: ENV.fetch('THREE_SIXTY_DIALOG_PARTNER_ID', nil)
  field :three_sixty_dialog_partner_username, readonly: true, default: ENV.fetch('THREE_SIXTY_DIALOG_PARTNER_USERNAME', nil)
  field :three_sixty_dialog_partner_password, readonly: true, default: ENV.fetch('THREE_SIXTY_DIALOG_PARTNER_PASSWORD', nil)
  field :three_sixty_dialog_partner_rest_api_endpoint, readonly: true, default: ENV.fetch('THREE_SIXTY_DIALOG_PARTNER_REST_API_ENDPOINT', 'https://stoplight.io/mocks/360dialog/360dialog-partner-api/24588693')

  field :three_sixty_dialog_whats_app_rest_api_endpoint, readonly: true,
                                                         default: ENV.fetch('THREE_SIXTY_DIALOG_WHATS_APP_REST_API_ENDPOINT', 'https://waba-sandbox.360dialog.io')
  field :three_sixty_dialog_whats_app_template_namespace

  field :email_from_address, readonly: true, default: ENV['EMAIL_FROM_ADDRESS'] || 'redaktion@localhost'
  field :inbound_email_password, readonly: true, default: ENV.fetch('RAILS_INBOUND_EMAIL_PASSWORD', nil)
  field :postmark_api_token, readonly: true, default: ENV.fetch('POSTMARK_API_TOKEN', nil)
  field :postmark_broadcasts_stream, readonly: true, default: ENV['POSTMARK_BROADCASTS_STREAM'] || 'broadcasts'
  field :postmark_transactional_stream, readonly: true, default: ENV['POSTMARK_TRANSACTIONAL_STREAM'] || 'outbound'

  field :mailserver_host, readonly: true, default: ENV['MAILSERVER_HOST'] || 'localhost'
  field :mailserver_port, readonly: true, default: ENV['MAILSERVER_PORT'] || 1025
end

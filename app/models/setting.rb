# frozen_string_literal: true

# RailsSettings Model
class Setting < RailsSettings::Base
  cache_prefix { 'v1' }

  delegate :onboarding_logo, to: :class
  delegate :onboarding_hero, to: :class

  def self.onboarding_logo
    ActiveStorage::Blob.find_by(id: onboarding_logo_blob_id)
  end

  def self.onboarding_logo=(blob)
    existing_blob = onboarding_logo
    existing_blob&.purge_later
    self.onboarding_logo_blob_id = blob.id
  end

  def self.onboarding_hero
    ActiveStorage::Blob.find_by(id: onboarding_hero_blob_id)
  end

  def self.onboarding_hero=(blob)
    existing_blob = onboarding_hero
    existing_blob&.purge_later
    self.onboarding_hero_blob_id = blob.id
  end

  def self.twilio_configured?
    whats_app_server_phone_number.present? && twilio_api_key_sid.present? && twilio_api_key_secret.present? && twilio_account_sid.present?
  end

  def self.three_sixty_dialog_configured?
    three_sixty_dialog_client_api_key.present?
  end

  def self.whats_app_configured?
    twilio_configured? || three_sixty_dialog_configured?
  end

  def self.signal_configured?
    signal_server_phone_number.present?
  end

  def self.threema_configured?
    threemarb_api_identity.present?
  end

  def self.telegram_configured?
    telegram_bot_api_key.present?
  end

  def self.email_configured?
    postmark_api_token.present?
  end

  def self.whats_app_onboarding_allowed?
    whats_app_configured? && channels.dig(:whats_app, :allow_onboarding)
  end

  def self.signal_onboarding_allowed?
    signal_configured? && channels.dig(:signal, :allow_onboarding)
  end

  def self.threema_onboarding_allowed?
    threema_configured? && channels.dig(:threema, :allow_onboarding)
  end

  def self.telegram_onboarding_allowed?
    telegram_configured? && channels.dig(:telegram, :allow_onboarding)
  end

  def self.email_onboarding_allowed?
    email_configured? && channels.dig(:email, :allow_onboarding)
  end

  field :project_name, default: ENV['HUNDRED_EYES_PROJECT_NAME'] || '100eyes'
  field :application_host, readonly: true, default: ENV['APPLICATION_HOSTNAME'] || 'localhost:3000'

  field :git_commit_sha, readonly: true, default: ENV.fetch('GIT_COMMIT_SHA', nil)
  field :git_commit_date, readonly: true, default: ENV.fetch('GIT_COMMIT_DATE', nil)

  field :onboarding_logo_blob_id, type: :integer
  field :onboarding_hero_blob_id, type: :integer
  field :onboarding_title, default: 'Hallo und herzlich willkommen!'
  field :onboarding_byline, default: ''
  field :onboarding_data_processing_consent_additional_info, default: ''
  field :onboarding_page, default: File.read(File.join('config', 'locales', 'onboarding', 'page.md'))
  field :onboarding_success_heading, default: File.read(File.join('config', 'locales', 'onboarding', 'success_heading.txt'))
  field :onboarding_success_text, default: File.read(File.join('config', 'locales', 'onboarding', 'success_text.txt'))
  field :onboarding_unauthorized_heading,
        default: File.read(File.join('config', 'locales', 'onboarding', 'unauthorized_heading.txt'))
  field :onboarding_unauthorized_text, default: File.read(File.join('config', 'locales', 'onboarding', 'unauthorized_text.txt'))
  field :onboarding_data_protection_link, default: 'https://tactile.news/100eyes-datenschutz/'
  field :onboarding_imprint_link, default: 'https://tactile.news/impressum/'
  field :onboarding_show_gdpr_modal, type: :boolean, readonly: true, default: ENV['ONBOARDING_SHOW_GDPR_MODAL'] || false

  field :onboarding_ask_for_additional_consent, type: :boolean, default: false
  field :onboarding_additional_consent_heading, default: ''
  field :onboarding_additional_consent_text, default: ''

  field :telegram_unknown_content_message, default: File.read(File.join('config', 'locales', 'telegram', 'unknown_content.txt'))
  field :telegram_contributor_not_found_message, default: File.read(File.join('config', 'locales', 'telegram', 'unknown_contributor.txt'))
  field :telegram_bot_api_key, readonly: true, default: ENV.fetch('TELEGRAM_BOT_API_KEY', nil)
  field :telegram_bot_username, readonly: true, default: ENV.fetch('TELEGRAM_BOT_USERNAME', nil)

  field :threema_unknown_content_message, default: File.read(File.join('config', 'locales', 'threema', 'unknown_content.txt'))
  field :threemarb_api_identity, readonly: true, default: ENV.fetch('THREEMARB_API_IDENTITY', nil)

  field :signal_server_phone_number, readonly: true, default: ENV.fetch('SIGNAL_SERVER_PHONE_NUMBER', nil)
  field :signal_monitoring_url, readonly: true, default: ENV.fetch('SIGNAL_MONITORING_URL', nil)
  field :signal_cli_rest_api_endpoint, readonly: true, default: ENV['SIGNAL_CLI_REST_API_ENDPOINT'] || 'http://localhost:8080'
  field :signal_cli_rest_api_attachment_path, readonly: true,
                                              default: ENV['SIGNAL_CLI_REST_API_ATTACHMENT_PATH'] || 'signal-cli-config/attachments/'
  field :signal_unknown_content_message, default: File.read(File.join('config', 'locales', 'signal', 'unknown_content.txt'))

  field :twilio_account_sid, readonly: true, default: ENV.fetch('TWILIO_ACCOUNT_SID', nil)
  field :twilio_api_key_sid, readonly: true, default: ENV.fetch('TWILIO_API_KEY_SID', nil)
  field :twilio_api_key_secret, readonly: true, default: ENV.fetch('TWILIO_API_KEY_SECRET', nil)
  field :whats_app_server_phone_number, readonly: true, default: ENV.fetch('WHATS_APP_SERVER_PHONE_NUMBER', nil)

  field :three_sixty_dialog_partner_token, default: ''
  field :three_sixty_dialog_partner_id, readonly: true, default: ENV.fetch('THREE_SIXTY_DIALOG_PARTNER_ID', nil)
  field :three_sixty_dialog_partner_username, readonly: true, default: ENV.fetch('THREE_SIXTY_DIALOG_PARTNER_USERNAME', nil)
  field :three_sixty_dialog_partner_password, readonly: true, default: ENV.fetch('THREE_SIXTY_DIALOG_PARTNER_PASSWORD', nil)
  field :three_sixty_dialog_partner_rest_api_endpoint, readonly: true, default: ENV.fetch('THREE_SIXTY_DIALOG_PARTNER_REST_API_ENDPOINT', 'https://stoplight.io/mocks/360dialog/360dialog-partner-api/24588693')

  field :three_sixty_dialog_client_api_key, default: ''
  field :three_sixty_dialog_client_id, default: ''
  field :three_sixty_dialog_client_waba_account_id, default: ''

  field :three_sixty_dialog_whats_app_rest_api_endpoint, readonly: true,
                                                         default: ENV.fetch('THREE_SIXTY_DIALOG_WHATS_APP_REST_API_ENDPOINT', 'https://waba-sandbox.360dialog.io')
  field :three_sixty_dialog_whats_app_template_namespace

  field :inbound_email_password, readonly: true, default: ENV.fetch('RAILS_INBOUND_EMAIL_PASSWORD', nil)
  field :email_from_address, readonly: true, default: ENV['EMAIL_FROM_ADDRESS'] || 'redaktion@localhost'
  field :postmark_api_token, readonly: true, default: ENV.fetch('POSTMARK_API_TOKEN', nil)
  field :postmark_broadcasts_stream, readonly: true, default: ENV['POSTMARK_BROADCASTS_STREAM'] || 'broadcasts'
  field :postmark_transactional_stream, readonly: true, default: ENV['POSTMARK_TRANSACTIONAL_STREAM'] || 'outbound'

  field :mailserver_host, readonly: true, default: ENV['MAILSERVER_HOST'] || 'localhost'
  field :mailserver_port, readonly: true, default: ENV['MAILSERVER_PORT'] || 1025

  field :channel_image
  field :about, default: File.read(File.join('config', 'locales', 'about.txt'))
  field :channels, type: :hash, default: {
    threema: { configured: threema_configured?, allow_onboarding: threema_configured? },
    telegram: { configured: telegram_configured?, allow_onboarding: telegram_configured? },
    email: { configured: email_configured?, allow_onboarding: email_configured? },
    signal: { configured: signal_configured?, allow_onboarding: signal_configured? },
    whats_app: { configured: whats_app_configured?, allow_onboarding: whats_app_configured? }
  }
end

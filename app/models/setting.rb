# frozen_string_literal: true

# RailsSettings Model
class Setting < RailsSettings::Base
  cache_prefix { 'v1' }

  def self.onboarding_logo
    ActiveStorage::Blob.find(onboarding_logo_blob_id)
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def self.onboarding_logo=(blob)
    existing_blob = onboarding_logo
    existing_blob&.purge_later
    self.onboarding_logo_blob_id = blob.id
  end

  def self.onboarding_hero
    ActiveStorage::Blob.find(onboarding_hero_blob_id)
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def self.onboarding_hero=(blob)
    existing_blob = onboarding_hero
    existing_blob&.purge_later
    self.onboarding_hero_blob_id = blob.id
  end

  field :project_name, default: ENV['HUNDRED_EYES_PROJECT_NAME'] || '100eyes'
  field :application_host, readonly: true, default: ENV['APPLICATION_HOSTNAME'] || 'localhost:3000'

  field :git_commit_sha, readonly: true, default: ENV['GIT_COMMIT_SHA']
  field :git_commit_date, readonly: true, default: ENV['GIT_COMMIT_DATE']

  field :onboarding_logo_blob_id, type: :integer
  field :onboarding_hero_blob_id, type: :integer
  field :onboarding_title, default: 'Hallo und herzlich willkommen!'
  field :onboarding_byline, default: ''
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
  field :telegram_bot_api_key, readonly: true, default: ENV['TELEGRAM_BOT_API_KEY']
  field :telegram_bot_username, readonly: true, default: ENV['TELEGRAM_BOT_USERNAME']

  field :threema_unknown_content_message, default: File.read(File.join('config', 'locales', 'threema', 'unknown_content.txt'))
  field :threemarb_api_identity, readonly: true, default: ENV['THREEMARB_API_IDENTITY']

  field :signal_server_phone_number, readonly: true, default: ENV['SIGNAL_SERVER_PHONE_NUMBER']
  field :signal_monitoring_url, readonly: true, default: ENV['SIGNAL_MONITORING_URL']
  field :signal_cli_rest_api_endpoint, readonly: true, default: ENV['SIGNAL_CLI_REST_API_ENDPOINT'] || 'http://localhost:8080'
  field :signal_cli_rest_api_attachment_path, readonly: true,
                                              default: ENV['SIGNAL_CLI_REST_API_ATTACHMENT_PATH'] || 'signal-cli-config/attachments/'
  field :signal_unknown_content_message, default: File.read(File.join('config', 'locales', 'signal', 'unknown_content.txt'))

  field :inbound_email_password, readonly: true, default: ENV['RAILS_INBOUND_EMAIL_PASSWORD']
  field :email_from_address, readonly: true, default: ENV['EMAIL_FROM_ADDRESS'] || 'redaktion@localhost'
  field :postmark_api_token, readonly: true, default: ENV['POSTMARK_API_TOKEN']
  field :postmark_broadcasts_stream, readonly: true, default: ENV['POSTMARK_BROADCASTS_STREAM'] || 'broadcasts'
  field :postmark_transactional_stream, readonly: true, default: ENV['POSTMARK_TRANSACTIONAL_STREAM'] || 'outbound'

  field :mailserver_host, readonly: true, default: ENV['MAILSERVER_HOST'] || 'localhost'
  field :mailserver_port, readonly: true, default: ENV['MAILSERVER_PORT'] || 1025
end

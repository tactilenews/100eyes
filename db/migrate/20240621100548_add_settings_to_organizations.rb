# frozen_string_literal: true

class AddSettingsToOrganizations < ActiveRecord::Migration[6.1]
  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def change
    # rubocop:disable Metrics/BlockLength
    change_table :organizations, bulk: true do |t|
      t.string :project_name, default: '100eyes'
      t.string :onboarding_title, default: 'Hallo und herzlich willkommen!'
      t.string :onboarding_byline, default: ''
      t.string :onboarding_data_processing_consent_additional_info, default: ''
      t.string :onboarding_page, default: File.read(File.join('config', 'locales', 'onboarding', 'page.md'))
      t.string :onboarding_success_heading, default: File.read(File.join('config', 'locales', 'onboarding', 'success_heading.txt'))
      t.string :onboarding_success_text, default: File.read(File.join('config', 'locales', 'onboarding', 'success_text.txt'))
      t.string :onboarding_unauthorized_heading,
               default: File.read(File.join('config', 'locales', 'onboarding', 'unauthorized_heading.txt'))
      t.string :onboarding_unauthorized_text, default: File.read(File.join('config', 'locales', 'onboarding', 'unauthorized_text.txt'))
      t.string :onboarding_data_protection_link, default: 'https://tactile.news/100eyes-datenschutz/'
      t.string :onboarding_imprint_link, default: 'https://tactile.news/impressum/'
      t.column :onboarding_show_gdpr_modal, :boolean, default: false
      t.column :onboarding_ask_for_additional_consent, :boolean, default: false
      t.string :onboarding_additional_consent_heading, default: ''
      t.string :onboarding_additional_consent_text, default: ''
      t.string :telegram_unknown_content_message, default: File.read(File.join('config', 'locales', 'telegram', 'unknown_content.txt'))
      t.string :telegram_contributor_not_found_message,
               default: File.read(File.join('config', 'locales', 'telegram', 'unknown_contributor.txt'))
      t.string :encrypted_telegram_bot_api_key
      t.string :encrypted_telegram_bot_api_key_iv
      t.string :telegram_bot_username
      t.string :threema_unknown_content_message, default: File.read(File.join('config', 'locales', 'threema', 'unknown_content.txt'))
      t.string :threemarb_api_identity
      t.string :encrypted_threemarb_api_secret
      t.string :encrypted_threemarb_api_secret_iv
      t.string :encrypted_threemarb_private
      t.string :encrypted_threemarb_private_iv
      t.string :twilio_api_key_sid
      t.string :encrypted_twilio_api_key_secret
      t.string :encrypted_twilio_api_key_secret_iv
      t.string :signal_server_phone_number
      t.string :signal_monitoring_url
      t.string :signal_unknown_content_message, default: File.read(File.join('config', 'locales', 'signal', 'unknown_content.txt'))
      t.string :twilio_account_sid
      t.string :whats_app_server_phone_number
      t.string :three_sixty_dialog_whats_app_template_namespace
      t.string :three_sixty_dialog_partner_id
      t.string :three_sixty_dialog_partner_username
      t.string :encrypted_three_sixty_dialog_partner_password
      t.string :encrypted_three_sixty_dialog_partner_password_iv
      t.string :encrypted_three_sixty_dialog_partner_token
      t.string :encrypted_three_sixty_dialog_partner_token_iv
      t.string :encrypted_three_sixty_dialog_client_api_key
      t.string :encrypted_three_sixty_dialog_client_api_key_iv
      t.string :three_sixty_dialog_client_id
      t.string :three_sixty_dialog_client_waba_account_id
      t.string :email_from_address
      t.string :whats_app_more_info_message, default: ''
      t.jsonb :onboarding_allowed, default: { threema: true, telegram: true, email: true, signal: true, whats_app: true }
      t.index :telegram_bot_username, unique: true
    end
    # rubocop:enable Metrics/BlockLength
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
end

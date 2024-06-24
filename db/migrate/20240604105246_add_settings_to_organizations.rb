# frozen_string_literal: true

# rubocop:disable Metrics/AbcSize, Metrics/MethodLength
class AddSettingsToOrganizations < ActiveRecord::Migration[6.1]
  def change
    change_table :organizations, bulk: true do |t|
      t.string :project_name
      t.integer :onboarding_logo_blob_id
      t.integer :onboarding_hero_blob_id
      t.string :onboarding_title
      t.string :onboarding_byline
      t.string :onboarding_data_processing_consent_additional_info
      t.string :onboarding_page
      t.string :onboarding_success_heading
      t.string :onboarding_success_text
      t.string :onboarding_unauthorized_heading
      t.string :onboarding_unauthorized_text
      t.string :onboarding_data_protection_link
      t.string :onboarding_imprint_link
      t.column :onboarding_show_gdpr_modal, :boolean
      t.column :onboarding_ask_for_additional_consent, :boolean, default: false
      t.string :onboarding_additional_consent_heading
      t.string :onboarding_additional_consent_text
      t.string :telegram_unknown_content_message
      t.string :telegram_contributor_not_found_message
      t.string :threema_unknown_content_message
      t.string :threemarb_api_identity
      t.string :encrypted_threemarb_api_secret
      t.string :encrypted_threemarb_api_secret_iv
      t.string :signal_server_phone_number
      t.string :signal_monitoring_url
      t.string :signal_unknown_content_message
      t.string :whats_app_server_phone_number
      t.string :email_from_address
      t.integer :channel_image_blob_id
      t.string :about
    end
  end
end
# rubocop:enable Metrics/AbcSize, Metrics/MethodLength

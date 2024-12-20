# frozen_string_literal: true

require 'administrate/base_dashboard'

class OrganizationDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    business_plan: Field::BelongsTo,
    contact_person: Field::BelongsTo,
    contributors: Field::HasMany,
    name: Field::String,
    upgrade_discount: Field::Number,
    users: Field::HasMany,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
    upgraded_business_plan_at: Field::DateTime,
    threemarb_api_identity: Field::String,
    threemarb_api_secret: Field::String,
    threemarb_private: Field::String,
    twilio_account_sid: Field::String,
    twilio_api_key_sid: Field::String,
    twilio_api_key_secret: Field::String,
    onboarding_allowed: Field::JSONB,
    onboarding_data_protection_link: Field::Url,
    onboarding_data_processing_consent_additional_info: Field::Text,
    onboarding_imprint_link: Field::Url,
    onboarding_ask_for_additional_consent: Field::Boolean,
    onboarding_additional_consent_heading: Field::String,
    onboarding_additional_consent_text: Field::String,
    channel_image: Field::ActiveStorage,
    whats_app_more_info_message: Field::Text,
    whats_app_profile_about: Field::Text,
    signal_complete_onboarding_link: Field::Url,
    whats_app_quick_reply_button_text: Field::JSONB
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    name
    contact_person
    contributors
    users
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    name
    contact_person
    business_plan
    upgrade_discount
    users
    created_at
    updated_at
    upgraded_business_plan_at
    whats_app_more_info_message
  ].freeze

  FORM_ATTRIBUTES_EDIT = %i[
    name
    contact_person
    business_plan
    upgrade_discount
    whats_app_profile_about
    whats_app_more_info_message
    onboarding_data_protection_link
    onboarding_data_processing_consent_additional_info
    onboarding_imprint_link
    onboarding_ask_for_additional_consent
    onboarding_additional_consent_heading
    onboarding_additional_consent_text
    onboarding_allowed
    channel_image
    signal_complete_onboarding_link
    whats_app_quick_reply_button_text
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(organization)
    organization.name
  end
end

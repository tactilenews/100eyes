# frozen_string_literal: true

require 'administrate/base_dashboard'

class OrganizationDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    business_plan: Field::BelongsTo,
    contact_person: Field::BelongsTo,
    contributors: Field::HasMany,
    name: Field::String,
    project_name: Field::String,
    upgrade_discount: Field::Number,
    users: Field::HasMany,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
    upgraded_business_plan_at: Field::DateTime,
    onboarding_allowed: Field::JSONB,
    onboarding_data_protection_link: Field::Url,
    onboarding_data_processing_consent_additional_info: Field::Text,
    onboarding_imprint_link: Field::Url,
    onboarding_ask_for_additional_consent: Field::Boolean,
    onboarding_additional_consent_heading: Field::String,
    onboarding_additional_consent_text: Field::String,
    channel_image: Field::ActiveStorage,
    whats_app_more_info_message: Field::Text,
    signal_complete_onboarding_link: Field::Url,
    whats_app_quick_reply_button_text: Field::JSONB,
    email_from_address: Field::Email,
    telegram_bot_username: Field::String,
    telegram_bot_api_key: Field::String.with_options(searchable: false),
    threemarb_api_identity: Field::String,
    threemarb_api_secret: Field::String.with_options(searchable: false),
    threemarb_private: Field::String.with_options(searchable: false),
    signal_server_phone_number: SetupSignalLinkField,
    messengers_about_text: Field::String,
    signal_username: Field::String,
    messengers_description_text: Field::String
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    name
    project_name
    contact_person
    email_from_address
    telegram_bot_username
    threemarb_api_identity
    signal_server_phone_number
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    name
    contact_person
    project_name
    messengers_about_text
    messengers_description_text
    whats_app_more_info_message
    whats_app_quick_reply_button_text
    signal_server_phone_number
    signal_username
    telegram_bot_username
    threemarb_api_identity
    email_from_address
    onboarding_data_protection_link
    onboarding_imprint_link
    onboarding_data_processing_consent_additional_info
    onboarding_ask_for_additional_consent
    onboarding_additional_consent_heading
    onboarding_additional_consent_text
    business_plan
    upgrade_discount
    onboarding_allowed
    channel_image
  ].freeze

  FORM_ATTRIBUTES_NEW = %i[
    name
    contact_person
    project_name
    messengers_about_text
    messengers_description_text
    whats_app_more_info_message
    whats_app_quick_reply_button_text
    signal_server_phone_number
    signal_username
    telegram_bot_username
    telegram_bot_api_key
    threemarb_api_identity
    threemarb_api_secret
    threemarb_private
    email_from_address
    onboarding_data_protection_link
    onboarding_imprint_link
    onboarding_ask_for_additional_consent
    onboarding_data_processing_consent_additional_info
    onboarding_additional_consent_heading
    onboarding_additional_consent_text
    business_plan
    upgrade_discount
    onboarding_allowed
    channel_image
  ].freeze

  FORM_ATTRIBUTES_EDIT = %i[
    name
    contact_person
    project_name
    messengers_about_text
    messengers_description_text
    whats_app_more_info_message
    whats_app_quick_reply_button_text
    signal_server_phone_number
    signal_username
    email_from_address
    onboarding_data_protection_link
    onboarding_imprint_link
    onboarding_data_processing_consent_additional_info
    onboarding_ask_for_additional_consent
    onboarding_additional_consent_heading
    onboarding_additional_consent_text
    business_plan
    upgrade_discount
    onboarding_allowed
    channel_image
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(organization)
    organization.name
  end
end

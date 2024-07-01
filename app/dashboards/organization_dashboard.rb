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
    twilio_api_key_secret: Field::String
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
    threemarb_api_identity
    twilio_account_sid
    twilio_api_key_sid
  ].freeze

  FORM_ATTRIBUTES = %i[
    business_plan
    upgrade_discount
    contact_person
    name
    threemarb_api_identity
    threemarb_api_secret
    threemarb_private
    twilio_account_sid
    twilio_api_key_sid
    twilio_api_key_secret
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(organization)
    organization.name
  end
end

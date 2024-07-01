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
    threemarb_private: Field::String
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    name
    contact_person
    business_plan
    upgrade_discount
    contributors
    users
    upgraded_business_plan_at
    threemarb_api_identity
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
  ].freeze

  FORM_ATTRIBUTES = %i[
    business_plan
    upgrade_discount
    contact_person
    name
    threemarb_api_identity
    threemarb_api_secret
    threemarb_private
  ].freeze

  COLLECTION_FILTERS = {}.freeze
end

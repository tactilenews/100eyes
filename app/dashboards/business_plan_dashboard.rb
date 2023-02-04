# frozen_string_literal: true

require 'administrate/base_dashboard'

class BusinessPlanDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    hours_of_included_support: Field::Number,
    name: Field::String,
    number_of_communities: Field::Number,
    number_of_contributors: Field::Number,
    number_of_users: Field::Number,
    price_per_month: Field::Number,
    setup_cost: Field::Number,
    valid_from: Field::DateTime,
    valid_until: Field::DateTime,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    name
    setup_cost
    price_per_month
    hours_of_included_support
    number_of_contributors
    number_of_users
    number_of_communities
    valid_from
    valid_until
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    hours_of_included_support
    name
    number_of_communities
    number_of_contributors
    number_of_users
    price_per_month
    setup_cost
    valid_from
    valid_until
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    hours_of_included_support
    name
    number_of_communities
    number_of_contributors
    number_of_users
    price_per_month
    setup_cost
    valid_from
    valid_until
  ].freeze

  COLLECTION_FILTERS = {}.freeze
  def display_resource(business_plan)
    "Current BusinessPlan: #{business_plan.name}"
  end
end

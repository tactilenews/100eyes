# frozen_string_literal: true

require 'administrate/base_dashboard'

class UserDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    first_name: Field::String,
    last_name: Field::String,
    email: Field::String,
    admin: Field::Boolean,
    otp_enabled: Field::Boolean.with_options(searchable: false),
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    first_name
    last_name
    email
    admin
    otp_enabled
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    first_name
    last_name
    email
    admin
    otp_enabled
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    first_name
    last_name
    email
    admin
    otp_enabled
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(user)
    user.name
  end
end

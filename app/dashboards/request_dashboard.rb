# frozen_string_literal: true

require 'administrate/base_dashboard'

class RequestDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    title: Field::String,
    text: Field::String,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
    broadcasted_at: Field::DateTime,
    messages: Field::HasMany
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    title
    created_at
    broadcasted_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    title
    text
    created_at
    updated_at
    broadcasted_at
    messages
  ].freeze

  FORM_ATTRIBUTES = %i[
    title
  ].freeze
end

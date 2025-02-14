# frozen_string_literal: true

require 'administrate/base_dashboard'

class MessageDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    sender: Field::Polymorphic.with_options(
      classes: [Contributor, User]
    ),
    recipient: Field::BelongsTo,
    request: Field::BelongsTo,
    created_at: Field::DateTime,
    text: Field::Text,
    raw_data: RawDataField,
    organization: Field::BelongsTo.with_options(
      searchable: true,
      searchable_fields: %w[name project_name]
    )
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    organization
    id
    sender
    recipient
    request
    text
    created_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    organization
    id
    sender
    text
    created_at
    updated_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = ATTRIBUTE_TYPES.keys
  FORM_ATTRIBUTES = [].freeze
end

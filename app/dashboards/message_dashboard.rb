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
    raw_data: RawDataField
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    sender
    recipient
    request
    text
    created_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = ATTRIBUTE_TYPES.keys
  FORM_ATTRIBUTES = [].freeze
end

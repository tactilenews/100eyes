# frozen_string_literal: true

require 'administrate/base_dashboard'

class MessageDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    sender: Field::BelongsTo,
    recipient: Field::BelongsTo,
    request: Field::BelongsTo,
    created_at: Field::DateTime,
    text: Field::Text
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

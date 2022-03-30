# frozen_string_literal: true

require 'administrate/base_dashboard'

class DelayedJobDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    queue: Field::String,
    handler: Field::Text,
    attempts: Field::Number,
    last_error: Field::Text,
    run_at: Field::DateTime,
    created_at: Field::DateTime,
    failed_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    queue
    attempts
    run_at
    created_at
    failed_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    queue
    handler
    attempts
    last_error
    created_at
    failed_at
  ].freeze

  FORM_ATTRIBUTES = [].freeze
end

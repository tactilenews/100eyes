# frozen_string_literal: true

require 'administrate/base_dashboard'

class ContributorDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    first_name: Field::String,
    last_name: Field::String,
    active: Field::Boolean,
    channels: Field::String.with_options(searchable: false),
    email: Field::String,
    username: Field::String,
    signal_phone_number: Field::String,
    threema_id: Field::String,
    note: Field::Text,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
    deactivated_at: Field::DateTime,
    data_processing_consented_at: Field::DateTime,
    additional_consent_given_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    first_name
    last_name
    channels
    active
    data_processing_consented_at
    additional_consent_given_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    first_name
    last_name
    active
    channels
    email
    username
    signal_phone_number
    threema_id
    data_processing_consented_at
    additional_consent_given_at
    note
    created_at
    updated_at
    deactivated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    first_name
    last_name
    active
    note
  ].freeze

  COLLECTION_FILTERS = {
    email: ->(resources) { resources.where.not(email: nil) },
    telegram: ->(resources) { resources.where.not(telegram_chat_id: nil) },
    threema: ->(resources) { resources.where.not(threema_id: nil) },
    signal: ->(resources) { resources.where.not(signal_phone_number: nil) }
  }.freeze

  def display_resource(contributor)
    contributor.name
  end
end

# frozen_string_literal: true

class Reply < ApplicationRecord
  include PgSearch::Model

  default_scope { order(created_at: :desc) }

  multisearchable against: :text

  belongs_to :user
  belongs_to :request
end

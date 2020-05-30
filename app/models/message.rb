# frozen_string_literal: true

class Message < ApplicationRecord
  include PgSearch::Model

  default_scope { order(created_at: :desc) }

  multisearchable against: :text

  belongs_to :user
  belongs_to :request, counter_cache: true
  has_many :photos, dependent: :destroy
end

# frozen_string_literal: true

class Reply < ApplicationRecord
  include PgSearch::Model
  pg_search_scope :search_text, against: :text

  belongs_to :user
  belongs_to :request
end

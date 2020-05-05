# frozen_string_literal: true

class Reply < ApplicationRecord
  include PgSearch::Model
  multisearchable against: :text

  belongs_to :user
  belongs_to :request
end

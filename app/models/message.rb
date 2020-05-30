# frozen_string_literal: true

class Message < ApplicationRecord
  include PgSearch::Model

  default_scope { order(created_at: :desc) }

  multisearchable against: :text

  belongs_to :user, optional: true
  belongs_to :request
  counter_culture :request, column_name: proc { |model| model.reply? ? 'replies_count' : nil }

  has_many :photos, dependent: :destroy

  def reply?
    !!user_id
  end
end

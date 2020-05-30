# frozen_string_literal: true

class Message < ApplicationRecord
  include PgSearch::Model

  default_scope { order(created_at: :desc) }

  multisearchable against: :text

  belongs_to :sender, class_name: 'User', optional: true
  belongs_to :recipient, class_name: 'User', optional: true
  belongs_to :request
  counter_culture :request, column_name: proc { |model| model.reply? ? 'replies_count' : nil }

  has_many :photos, dependent: :destroy

  def reply?
    !!sender_id
  end
end

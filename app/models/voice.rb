# frozen_string_literal: true

class Voice < ApplicationRecord
  belongs_to :message
  has_one_attached :attachment
  validates :attachment, presence: true, blob: { content_type: :audio }
end

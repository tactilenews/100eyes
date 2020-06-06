# frozen_string_literal: true

class Photo < ApplicationRecord
  belongs_to :message
  counter_culture :message
  has_one_attached :image
  validates :image, presence: true, blob: { content_type: :image }
end

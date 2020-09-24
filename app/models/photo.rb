# frozen_string_literal: true

class Photo < ApplicationRecord
  belongs_to :message
  counter_culture :message
  has_one_attached :image
  validates :image, presence: true, blob: { content_type: :image }

  def thumbnail
    image.variant(resize: '200x200').processed
  end
end

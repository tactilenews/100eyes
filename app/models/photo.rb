# frozen_string_literal: true

class Photo < ApplicationRecord
  belongs_to :message
  counter_culture :message
  has_one_attached :attachment
  validates :attachment, presence: true, blob: { content_type: :image }

  def thumbnail
    attachment.variant(resize_to_fit: [200, 200]).processed
  end
end

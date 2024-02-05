# frozen_string_literal: true

class Message::File < ApplicationRecord
  belongs_to :message
  counter_culture :message, column_name: proc { |model| model.image_attachment? ? 'photos_count' : nil }
  has_one_attached :attachment
  validates :attachment, presence: true

  def thumbnail
    attachment
  end

  def image_attachment?
    attachment.blob.content_type.match?(/image/)
  end
end

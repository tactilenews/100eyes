# frozen_string_literal: true

class Message::File < ApplicationRecord
  belongs_to :message
  has_one_attached :attachment
  validates :attachment, presence: true

  def thumbnail
    attachment
  end
end

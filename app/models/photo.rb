# frozen_string_literal: true

class Photo < ApplicationRecord
  belongs_to :reply
  has_one_attached :image
end

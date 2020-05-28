# frozen_string_literal: true

class Photo < ApplicationRecord
  belongs_to :reply, counter_cache: true
  has_one_attached :image
end

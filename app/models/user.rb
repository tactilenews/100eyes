# frozen_string_literal: true

class User < ApplicationRecord
  has_many :feedbacks, dependent: :destroy
end

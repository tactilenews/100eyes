# frozen_string_literal: true

class Issue < ApplicationRecord
  has_many :feedbacks, dependent: :destroy
end

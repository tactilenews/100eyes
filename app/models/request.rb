# frozen_string_literal: true

class Request < ApplicationRecord
  has_many :feedbacks, dependent: :destroy
end

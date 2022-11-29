# frozen_string_literal: true

class Organization < ApplicationRecord
  belongs_to :business_plan
  has_many :users, dependent: :destroy
end

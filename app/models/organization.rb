# frozen_string_literal: true

class Organization < ApplicationRecord
  belongs_to :business_plan
  belongs_to :contact_person, class_name: 'User', optional: true
  has_many :users, class_name: 'User', dependent: :destroy
  has_many :contributors, dependent: :destroy
end

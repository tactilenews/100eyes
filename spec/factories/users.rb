# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence :email do |n|
      "user#{n}@example.org"
    end
    password { 'xZFXzux2Moj8wJkA0VBl' }
    confirmed_at { Time.zone.now }
  end
end

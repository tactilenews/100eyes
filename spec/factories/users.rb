# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    first_name { 'John' }
    last_name { 'Doe' }
    sequence :email do |n|
      "user#{n}@example.org"
    end
  end
end

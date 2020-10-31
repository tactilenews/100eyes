# frozen_string_literal: true

FactoryBot.define do
  factory :contributor do
    first_name { 'John' }
    last_name { 'Doe' }
    sequence :email do |n|
      "contributor#{n}@example.org"
    end
  end
end

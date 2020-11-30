# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence :email do |n|
      "user#{n}@example.org"
    end
    password { 'UMyD1aJVWBIwoTsdl3Mb' }
  end
end

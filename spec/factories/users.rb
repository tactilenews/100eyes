# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence :email do |n|
      "user#{n}@example.org"
    end
    password { Faker::Internet.password(min_length: 20, max_length: 128) }
    otp_enabled { true }
    organization
  end
end

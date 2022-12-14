# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence :email do |n|
      "user#{n}@example.org"
    end
    sequence :first_name do |n|
      "FirstName#{n}"
    end
    sequence :last_name do |n|
      "LastName#{n}"
    end
    password { Faker::Internet.password(min_length: 20, max_length: 128) }
    otp_enabled { true }
  end
end

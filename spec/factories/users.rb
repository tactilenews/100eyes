# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    password { Faker::Internet.password(min_length: 20, max_length: 128) }
    otp_enabled { true }

    after(:build) do |user, evaluator|
      user.organizations << create(:organization) unless user.admin? || evaluator.organizations.present?
      user.class.skip_callback(:create, :before, :set_must_reset_password, raise: false)
    end

    after(:create) do |_user|
      User.set_callback(:create, :before, :set_must_reset_password)
    end
  end
end

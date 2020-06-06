# frozen_string_literal: true

FactoryBot.define do
  factory :message do
    association :sender, factory: :user
    association :request
    trait :with_a_photo do
      after(:create) do |message|
        create(:photo, message: message)
      end
    end
  end
end

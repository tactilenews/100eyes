# frozen_string_literal: true

FactoryBot.define do
  factory :reply do
    association :user
    association :request
    trait :with_a_photo do
      after(:create) do |reply|
        create(:photo, reply: reply)
      end
    end
  end
end

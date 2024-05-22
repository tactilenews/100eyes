# frozen_string_literal: true

FactoryBot.define do
  factory :contributor do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    data_processing_consent { true }
    email { Faker::Internet.email }

    trait :with_an_avatar do
      after(:build) do |contributor|
        contributor.avatar.attach(
          io: Rails.root.join('example-image.png').open,
          filename: 'example-image.png'
        )
      end
    end
  end
end

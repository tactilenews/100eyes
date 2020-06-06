# frozen_string_literal: true

FactoryBot.define do
  factory :message do
    association :sender, factory: :user
    association :request
    trait :with_a_photo do
      after(:create) do |message|
        create(
          :photo,
          message: message,
          image: Rack::Test::UploadedFile.new(
            Rails.root.join('example-image.png'),
            'image/png'
          )
        )
      end
    end
  end
end

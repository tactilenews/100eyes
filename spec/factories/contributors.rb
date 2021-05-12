# frozen_string_literal: true

FactoryBot.define do
  factory :contributor do
    first_name { 'John' }
    last_name { 'Doe' }
    data_processing_consent { true }
    sequence :email do |n|
      "contributor#{n}@example.org"
    end

    trait :with_an_avatar do
      avatar { Rack::Test::UploadedFile.new(Rails.root.join('example-image.png'), 'image/png') }
    end

    trait :manually_created do
      data_processing_consent { false }
    end
  end
end

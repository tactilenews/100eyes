# frozen_string_literal: true

FactoryBot.define do
  factory :message do
    unknown_content { false }
    association :sender, factory: :user
    association :request
    with_sender

    after(:build) do |message|
      message.raw_data.attach(
        io: StringIO.new(JSON.generate({ text: 'Hello' })),
        filename: 'text.json',
        content_type: 'application/json'
      )
    end

    trait :with_sender do
      recipient { nil }
      association :sender, factory: :user
    end

    trait :with_recipient do
      sender { nil }
      association :recipient, factory: :user
    end

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

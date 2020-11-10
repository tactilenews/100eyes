# frozen_string_literal: true

FactoryBot.define do
  factory :message do
    created_at { Time.zone.now }
    unknown_content { false }
    association :sender, factory: :contributor
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
      association :sender, factory: :contributor
    end

    trait :with_recipient do
      sender { nil }
      association :recipient, factory: :contributor
    end

    trait :with_voice do
      after(:create) do |message|
        create(:voice, message: message)
      end
    end

    trait :with_a_photo do
      after(:create) do |message|
        create(:photo, message: message)
      end
    end
  end
end

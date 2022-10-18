# frozen_string_literal: true

FactoryBot.define do
  factory :message do
    created_at { Time.zone.now }
    unknown_content { false }
    text { Faker::Lorem.sentence }
    request
    inbound

    after(:build) do |message|
      message.raw_data.attach(
        io: StringIO.new(JSON.generate({ text: 'Hello' })),
        filename: 'text.json',
        content_type: 'application/json'
      )
    end

    trait :inbound do
      recipient { nil }
      association :sender, factory: :contributor
    end

    trait :outbound do
      association :sender, factory: :user
      association :recipient, factory: :contributor
    end

    trait :with_file do
      after(:create) do |message|
        create(:file, message: message)
      end
    end

    trait :with_a_photo do
      after(:create) do |message|
        create(:photo, message: message)
      end
    end
  end
end

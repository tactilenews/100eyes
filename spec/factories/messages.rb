# frozen_string_literal: true

FactoryBot.define do
  factory :message do
    created_at { Time.zone.now }
    unknown_content { false }
    text { Faker::Lorem.sentence }
    request
    inbound
    organization

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
      transient do
        attachment { Rack::Test::UploadedFile.new(Rails.root.join('example-audio.oga'), 'audio/ogg') }
      end
      after(:create) do |message, evaluator|
        create(:file, message: message, attachment: evaluator.attachment)
      end
    end
  end
end

# frozen_string_literal: true

FactoryBot.define do
  factory :request do
    organization
    title { 'I need a title' }
    text { 'I am a request' }
    broadcasted_at { Time.current }
    user

    trait :with_interlapping_messages_from_two_contributors do
      after(:create) do |request, _|
        adam = create(:contributor, first_name: 'Adam', last_name: 'Ackermann')
        zora = create(:contributor, first_name: 'Zora', last_name: 'Zimmermann')

        create(:message, request: request, sender: adam, created_at: 3.hours.ago)
        create(:message, request: request, sender: zora, created_at: 2.hours.ago)
        create(:message, request: request, sender: adam, created_at: 1.hour.ago)
      end
    end
  end
end

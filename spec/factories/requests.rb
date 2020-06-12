# frozen_string_literal: true

FactoryBot.define do
  factory :request do
    text { 'I am a request' }

    trait :with_interlapping_messages_from_two_users do
      after(:create) do |request, _|
        adam = create(:user, name: 'Adam Ackermann')
        zora = create(:user, name: 'Zora Zimmermann')

        create(:message, request: request, sender: adam, created_at: 3.hours.ago)
        create(:message, request: request, sender: zora, created_at: 2.hours.ago)
        create(:message, request: request, sender: adam, created_at: 1.hour.ago)
      end
    end
  end
end

# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
FactoryBot.define do
  factory :contributor do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    data_processing_consent { true }
    email { Faker::Internet.email }

    trait :inactive do
      deactivated_at { Time.current }
    end

    trait :with_an_avatar do
      after(:build) do |contributor|
        contributor.avatar.attach(
          io: Rails.root.join('example-image.png').open,
          filename: 'example-image.png'
        )
      end
    end

    trait :threema_contributor do
      after(:build) do |contributor|
        contributor.email = nil
        contributor.threema_id = Faker::Alphanumeric.alpha(number: 8)
      end
    end

    trait :telegram_contributor do
      after(:build) do |contributor|
        contributor.email = nil
        contributor.telegram_id = Faker::Number.number(digits: 9)
      end
    end

    trait :signal_contributor do
      after(:build) do |contributor|
        contributor.email = nil
        contributor.signal_phone_number = Faker::PhoneNumber.cell_phone_in_e164
      end
    end

    trait :signal_contributor_uuid do
      after(:build) do |contributor|
        contributor.email = nil
        contributor.signal_uuid = Faker::Internet.uuid
      end
    end

    trait :whats_app_contributor do
      after(:build) do |contributor|
        contributor.email = nil
        contributor.whats_app_phone_number = Faker::PhoneNumber.cell_phone_in_e164
      end
    end

    trait :skip_validations do
      to_create { |instance| instance.save(validate: false) }
    end
  end
end
# rubocop:enable Metrics/BlockLength

# frozen_string_literal: true

FactoryBot.define do
  factory :activity_notification do
    recipient { nil }
    type { '' }
    params { '' }
    read_at { '2022-06-07 14:01:43' }
  end
end

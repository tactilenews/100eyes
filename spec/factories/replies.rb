# frozen_string_literal: true

FactoryBot.define do
  factory :reply do
    association :user
    association :request
  end
end

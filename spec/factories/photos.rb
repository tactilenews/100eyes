# frozen_string_literal: true

FactoryBot.define do
  factory :photo do
    association :message
  end
end

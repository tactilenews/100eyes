# frozen_string_literal: true

FactoryBot.define do
  factory :json_web_token do
    invalidated_jwt { nil }
  end
end

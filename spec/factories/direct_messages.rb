# frozen_string_literal: true

FactoryBot.define do
  factory :direct_message, parent: :message do
    outbound
    broadcasted { false }
  end
end

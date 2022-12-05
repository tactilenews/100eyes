# frozen_string_literal: true

FactoryBot.define do
  factory :organization do
    business_plan

    name { '100eyes' }

    transient do
      users_count { 5 }
    end

    users do
      Array.new(users_count) { association(:user, organization: instance) }
    end
  end
end

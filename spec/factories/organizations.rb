# frozen_string_literal: true

FactoryBot.define do
  factory :organization do
    business_plan

    name { '100eyes' }
    upgrade_discount { 10 }

    transient do
      users_count { 0 }
      contributors_count { 0 }
    end

    users do
      Array.new(users_count) { association(:user, organization: instance) }
    end

    contributors do
      Array.new(contributors_count) { association(:contributor, organization: instance) }
    end
  end
end

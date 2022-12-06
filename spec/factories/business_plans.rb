# frozen_string_literal: true

FactoryBot.define do
  factory :business_plan do
    name { 'Free' }
    price_per_month { 0 }
    setup_cost { 0 }
    hours_of_included_support { 0 }
    number_of_users { 5 }
    number_of_contributors { 150 }
    number_of_communities { 1 }
    valid_from { Time.current }
    valid_until { Time.current + 6.months }
  end
end

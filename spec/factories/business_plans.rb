# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
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

    trait :ngo_basic do
      name { 'NGO basic' }
      price_per_month { 195 }
      setup_cost { 0 }
      hours_of_included_support { 0 }
      number_of_users { 3 }
      number_of_contributors { 150 }
      number_of_communities { 1 }
      valid_from { nil }
      valid_until { nil }
    end

    trait :startup_basic do
      name { 'Startup basic' }
      price_per_month { 195 }
      setup_cost { 0 }
      hours_of_included_support { 0 }
      number_of_users { 3 }
      number_of_contributors { 150 }
      number_of_communities { 1 }
      valid_from { nil }
      valid_until { nil }
    end

    trait :editorial_basic do
      name { 'Editorial basic' }
      price_per_month { 395 }
      setup_cost { 2_195 }
      hours_of_included_support { 0 }
      number_of_users { 1 }
      number_of_contributors { 50 }
      number_of_communities { 1 }
      valid_from { nil }
      valid_until { nil }
    end

    trait :editorial_pro do
      name { 'Editorial pro' }
      price_per_month { 495 }
      setup_cost { 2_195 }
      hours_of_included_support { 5 }
      number_of_users { 3 }
      number_of_contributors { 150 }
      number_of_communities { 1 }
      valid_from { nil }
      valid_until { nil }
    end

    trait :editorial_enterprise do
      name { 'Editorial enterprise' }
      price_per_month { 995 }
      setup_cost { 2_195 }
      hours_of_included_support { 10 }
      number_of_users { 5 }
      number_of_contributors { 500 }
      number_of_communities { 3 }
      valid_from { nil }
      valid_until { nil }
    end

    trait :corporate_basic do
      name { 'Corporate basic' }
      price_per_month { 395 }
      setup_cost { 2_195 }
      hours_of_included_support { 0 }
      number_of_users { 1 }
      number_of_contributors { 50 }
      number_of_communities { 1 }
      valid_from { nil }
      valid_until { nil }
    end

    trait :corporate_pro do
      name { 'Corporate pro' }
      price_per_month { 495 }
      setup_cost { 2_195 }
      hours_of_included_support { 5 }
      number_of_users { 3 }
      number_of_contributors { 150 }
      number_of_communities { 1 }
      valid_from { nil }
      valid_until { nil }
    end

    trait :corporate_enterprise do
      name { 'Corporate enterprise' }
      price_per_month { 995 }
      setup_cost { 2_195 }
      hours_of_included_support { 10 }
      number_of_users { 5 }
      number_of_contributors { 500 }
      number_of_communities { 3 }
      valid_from { nil }
      valid_until { nil }
    end
  end
end
# rubocop:enable Metrics/BlockLength

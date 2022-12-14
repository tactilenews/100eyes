# frozen_string_literal: true

BUSINESS_PLANS = [
  {
    name: 'Free',
    price_per_month: 0,
    setup_cost: 0,
    hours_of_included_support: 0,
    number_of_users: 5,
    number_of_contributors: 150,
    number_of_communities: 1,
    valid_from: nil,
    valid_until: nil
  },
  {
    name: 'NGO basic',
    price_per_month: 195,
    setup_cost: 0,
    hours_of_included_support: 0,
    number_of_users: 3,
    number_of_contributors: 150,
    number_of_communities: 1,
    valid_from: nil,
    valid_until: nil
  },
  {
    name: 'Startup basic',
    price_per_month: 195,
    setup_cost: 995,
    hours_of_included_support: 0,
    number_of_users: 3,
    number_of_contributors: 150,
    number_of_communities: 1,
    valid_from: nil,
    valid_until: nil
  },
  {
    name: 'Editorial basic',
    price_per_month: 395,
    setup_cost: 2_195,
    hours_of_included_support: 0,
    number_of_users: 1,
    number_of_contributors: 50,
    number_of_communities: 1,
    valid_from: nil,
    valid_until: nil
  },
  {
    name: 'Editorial pro',
    price_per_month: 495,
    setup_cost: 2_195,
    hours_of_included_support: 5,
    number_of_users: 3,
    number_of_contributors: 150,
    number_of_communities: 1,
    valid_from: Time.current,
    valid_until: Time.current + 6.months
  },
  {
    name: 'Editorial enterprise',
    price_per_month: 995,
    setup_cost: 2_195,
    hours_of_included_support: 10,
    number_of_users: 5,
    number_of_contributors: 500,
    number_of_communities: 3,
    valid_from: nil,
    valid_until: nil
  },
  {
    name: 'Corporate basic',
    price_per_month: 395,
    setup_cost: 2_195,
    hours_of_included_support: 0,
    number_of_users: 1,
    number_of_contributors: 50,
    number_of_communities: 1,
    valid_from: nil,
    valid_until: nil
  },
  {
    name: 'Corporate pro',
    price_per_month: 495,
    setup_cost: 2_195,
    hours_of_included_support: 5,
    number_of_users: 3,
    number_of_contributors: 150,
    number_of_communities: 1,
    valid_from: nil,
    valid_until: nil
  },
  {
    name: 'Corporate enterprise',
    price_per_month: 995,
    setup_cost: 2_195,
    hours_of_included_support: 10,
    number_of_users: 5,
    number_of_contributors: 500,
    number_of_communities: 3,
    valid_from: nil,
    valid_until: nil
  }
].freeze
desc 'Create business plans'
task create_business_plan_with_index: :environment do |_task, args|
  args.extras.each do |index|
    BusinessPlan.create_or_find_by(BUSINESS_PLANS[index.to_i])
    puts "Created #{BUSINESS_PLANS[index.to_i][:name]}"
  end
end

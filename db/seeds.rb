# frozen_string_literal: true

# rubocop:disable Rails/Output
password = 'go3LS4gvPuuSoq2m0B2n'
otp_secret_key = 'THDBCRGPERS75F7IDDLISUDC6N2YYG3V'
business_plans = [
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
    valid_from: Time.current,
    valid_until: Time.current + 6.months
  },
  {
    name: 'Editorial pro',
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
]
business_plans = business_plans.each do |business_plan|
  BusinessPlan.create_or_find_by(business_plan)
end
organization = Organization.create_or_find_by(name: '100eyes',
                                              business_plan: BusinessPlan.where.not(
                                                valid_from: nil, valid_until: nil
                                              ).first)
admin = User.create_or_find_by(email: 'redaktion@tactile.news', first_name: 'Dennis', last_name: 'Schröder', password: password,
                               admin: true, otp_secret_key: otp_secret_key)
user = User.create_or_find_by(email: 'contact-person@example_organization.org', first_name: 'ConactFor', last_name: 'Organization',
                              password: password, otp_secret_key: otp_secret_key, organization: organization)
organization.update(contact_person: user)
puts 'BusinesPlans:'
business_plans.pluck(:name).each_with_index do |business_plan_name, index|
  puts "#{index + 1}: #{business_plan_name}"
end
puts "Admin with email #{admin.email}"
puts "User with email #{user.email}"
# rubocop:enable Rails/Output

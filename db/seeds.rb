# frozen_string_literal: true

# rubocop:disable Rails/Output
password = ENV.fetch('SEED_USER_PASSWORD', SecureRandom.alphanumeric(20))
otp_secret_key = ENV.fetch('SEED_USER_OTP_SECRET', User.otp_random_secret)

business_plan = BusinessPlan.create_or_find_by!(
  name: 'Free',
  price_per_month: 0,
  setup_cost: 0,
  hours_of_included_support: 0,
  number_of_users: 5,
  number_of_contributors: 150,
  number_of_communities: 1,
  valid_from: Time.current,
  valid_until: Time.current + 6.months
)
organization = Organization.create_or_find_by!(
  name: '100eyes',
  project_name: 'HundredEyes',
  upgrade_discount: 10,
  business_plan: business_plan,
  signal_username: 'HundredEyes',
  signal_server_phone_number: '+4915111111111'
)
admin = User.create_or_find_by!(email: 'redaktion@tactile.news', first_name: 'Dennis', last_name: 'Schröder', password: password,
                                admin: true, otp_secret_key: otp_secret_key)
user = User.create_or_find_by!(email: 'contact-person@example-organization.org', first_name: 'Contact Person', last_name: 'Organization',
                               password: password, otp_secret_key: otp_secret_key, organizations: [organization])
organization.update(contact_person: user)
puts "Organization with name #{organization.name}"
puts "Admin with email #{admin.email}"
puts "User with email #{user.email}"
# rubocop:enable Rails/Output

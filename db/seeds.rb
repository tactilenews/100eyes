# frozen_string_literal: true

# rubocop:disable Rails/Output
require 'faker'

Faker::Config.locale = :de

password = ENV.fetch('SEED_USER_PASSWORD', SecureRandom.alphanumeric(20))
otp_secret_key = ENV.fetch('SEED_USER_OTP_SECRET', User.otp_random_secret)

business_plan = BusinessPlan.find_or_initialize_by(name: 'Free')
business_plan.assign_attributes(
  price_per_month: 0,
  setup_cost: 0,
  hours_of_included_support: 0,
  number_of_users: 5,
  number_of_contributors: 150,
  number_of_communities: 1,
  valid_from: business_plan.valid_from || Time.current,
  valid_until: business_plan.valid_until || (Time.current + 6.months)
)
business_plan.save!
organization = Organization.find_or_initialize_by(name: '100eyes')
organization.assign_attributes(
  project_name: 'HundredEyes',
  upgrade_discount: 10,
  business_plan: business_plan,
  signal_username: 'HundredEyes',
  signal_server_phone_number: '+491****1111'
)
organization.save!
# Skip the before_create callback that unconditionally sets must_reset_password: true,
# so seed users can sign in to previews without being forced to change their password.
# Use find_or_initialize_by + save! so re-runs are idempotent: Clearance adds a model-level
# uniqueness validation that causes create_or_find_by! to raise RecordInvalid (not
# RecordNotUnique) on duplicates, which create_or_find_by! does not rescue.
User.skip_callback(:create, :before, :set_must_reset_password)
admin = User.find_or_initialize_by(email: 'redaktion@tactile.news')
if admin.new_record?
  admin.first_name = 'Dennis'
  admin.last_name = 'Schröder'
  admin.password = password
  admin.admin = true
  admin.otp_secret_key = otp_secret_key
  admin.must_reset_password = false
  admin.save!
end
user = User.find_or_initialize_by(email: 'contact-person@example-organization.org')
if user.new_record?
  user.first_name = 'Contact Person'
  user.last_name = 'Organization'
  user.password = password
  user.otp_secret_key = otp_secret_key
  user.organizations = [organization]
  user.must_reset_password = false
  user.save!
end
User.set_callback(:create, :before, :set_must_reset_password)
organization.update(contact_person: user)
puts "Organization with name #{organization.name}"
puts "Admin with email #{admin.email} and password #{password}"
puts "User with email #{user.email} and password #{password}"

# Skip delivery callbacks -- preview has no messaging backends
Message.skip_callback(:commit, :after, :send_if_outbound, raise: false)

# ---------------------------------------------------------------------------
# Contributors -- realistic mix for previewing contributor lists and lazy-load
# (idempotent: skipped if contributors already exist for this organization)
# ---------------------------------------------------------------------------
CONTRIBUTOR_COUNT = 50

if organization.contributors.none?
  puts "Seeding #{CONTRIBUTOR_COUNT} contributors..."

  contributors = CONTRIBUTOR_COUNT.times.map do
    Contributor.create!(
      organization: organization,
      first_name: Faker::Name.first_name,
      last_name: Faker::Name.last_name,
      email: Faker::Internet.unique.email,
      data_processing_consented_at: rand(180).days.ago,
      note: Faker::Lorem.sentence
    )
  end

  # A handful of inactive/unsubscribed contributors for realistic state variety
  contributors.first(5).each { |c| c.update!(deactivated_at: rand(30).days.ago, deactivated_by_user: admin) }
  contributors[5..7].each { |c| c.update!(unsubscribed_at: rand(14).days.ago) }

  puts "Seeded #{Contributor.count} contributors (#{Contributor.active.count} active)"
else
  contributors = organization.contributors.to_a
  puts "Skipped contributors (#{Contributor.count} already exist)"
end

# ---------------------------------------------------------------------------
# Requests -- a variety of broadcasted questions with realistic timestamps
# (idempotent: skipped if requests already exist for this organization)
# ---------------------------------------------------------------------------
REQUEST_COUNT = 15

if organization.requests.none?
  puts "Seeding #{REQUEST_COUNT} requests..."

  requests = REQUEST_COUNT.times.map do
    created_at     = rand(90).days.ago
    broadcasted_at = created_at + rand(1..48).hours

    Request.create!(
      organization: organization,
      user: user,
      title: Faker::Lorem.question(word_count: 6),
      text: Faker::Lorem.paragraph(sentence_count: 3),
      created_at: created_at,
      broadcasted_at: broadcasted_at
    )
  end

  puts "Seeded #{Request.count} requests"
else
  requests = organization.requests.to_a
  puts "Skipped requests (#{Request.count} already exist)"
end

# ---------------------------------------------------------------------------
# Messages -- inbound replies from contributors per request
# (idempotent: skipped if messages already exist for this organization)
# ---------------------------------------------------------------------------
if organization.messages.none?
  active_contributors = contributors.reject { |c| c.deactivated_at? || c.unsubscribed_at? }

  puts 'Seeding reply messages...'

  requests.each do |request|
    next unless request.broadcasted_at

    reply_count = rand(3..12)
    active_contributors.sample(reply_count).each do |contributor|
      replied_at = Time.zone.at(rand(request.broadcasted_at.to_i..Time.current.to_i))
      Message.create!(
        organization: organization,
        request: request,
        sender: contributor,
        text: Faker::Lorem.paragraph(sentence_count: rand(1..4)),
        unknown_content: false,
        created_at: replied_at,
        updated_at: replied_at,
        raw_data: [{ io: StringIO.new(JSON.generate({ text: 'reply' })), filename: 'raw.json', content_type: 'application/json' }]
      )
    end
  end

  puts "Seeded #{Message.count} messages"
else
  puts "Skipped messages (#{Message.count} already exist)"
end
# rubocop:enable Rails/Output

# frozen_string_literal: true

require 'factory_bot_rails'
require 'faker'

request_count = 20

business_plan = BusinessPlan.find_by(name: 'Free')
organizations = 3.times.collect do
  Organization.create!(
    name: Faker::Company.name,
    project_name: Faker::Company.name,
    upgrade_discount: rand(0..25),
    business_plan: business_plan,
    telegram_bot_username: Faker::Internet.username
  )
end
users = 10.times.collect do
  FactoryBot.create(:user, organizations: [organizations.sample])
end

# images = 10.times.map { URI(Faker::Avatar.image(size: '50x50', format: 'png', set: 'set5')) }

FactoryBot.modify do
  factory :contributor do
    organization { organizations.sample }
    # after(:build) do |contributor|
    #   image = images.sample
    #   contributor.avatar.attach(
    #     io: image.open,
    #     filename: File.basename(image.path)
    #   )
    # end
  end
end

FactoryBot.modify do
  factory :request do
    title { Faker::Lorem.question }
    text { Faker::Lorem.paragraph }
    user { users.sample }
  end
end

Rails.logger.debug 'Seeding requests..'
requests = request_count.times.collect do
  created_at = Time.zone.at(rand(14.days.ago..Time.current))
  broadcasted_at = Time.zone.at(rand(created_at..Time.current))
  FactoryBot.build(:request,
                   created_at: created_at,
                   broadcasted_at: broadcasted_at,
                   organization: organizations.sample) do |request|
    request.class.skip_callback(:create, :after, :broadcast_request, raise: false)
    request.save!
  end
end

Rails.logger.debug 'Seeding contributors..'

FactoryBot.create_list(:contributor, 5)
FactoryBot.create_list(:contributor, 20, :threema_contributor, :skip_validations)
FactoryBot.create_list(:contributor, 30, :telegram_contributor)
FactoryBot.create_list(:contributor, 40, :signal_contributor)
FactoryBot.create_list(:contributor, 100, :whats_app_contributor)
contributors = Contributor.all

FactoryBot.modify do
  factory :message do
    sender_type { 'Contributor' }
    text { Faker::Lorem.paragraph }
    unknown_content { false }
    broadcasted { false }
    sender { contributors.sample }
    recipient { nil }
  end
end

Rails.logger.debug 'Seeding messages..'
message_count = request_count * (contributors.count * 0.5).to_i
message_count.times do
  request = requests.sample
  created_at = Time.zone.at(rand(request.broadcasted_at..Time.current))
  FactoryBot.build(:message, request: request, created_at: created_at, updated_at: created_at) do |message|
    message.class.skip_callback(:create, :after, :send_if_outbound, raise: false)
    message.save!
  end
end

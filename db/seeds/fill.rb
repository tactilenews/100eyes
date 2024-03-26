# frozen_string_literal: true

require 'factory_bot_rails'
require 'faker'

contributors_count = 100
request_count = 200
message_count = request_count * (contributors_count * 0.5).to_i
message_time = Faker::Time.backward(days: 14)

users = User.all

# images = 10.times.map { URI(Faker::Avatar.image(size: '50x50', format: 'png', set: 'set5')) }

FactoryBot.modify do
  factory :contributor do
    data_processing_consent { true }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    note { Faker::Movies::HitchhikersGuideToTheGalaxy.quote }

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
requests = FactoryBot.build_list(:request, request_count) do |request|
  request.class.skip_callback(:create, :after, :broadcast_request, raise: false)
  request.save!
end

Rails.logger.debug 'Seeding contributors..'
contributors = FactoryBot.create_list(:contributor, contributors_count)

FactoryBot.modify do
  factory :message do
    created_at { message_time }
    updated_at { message_time }
    sender_type { 'Contributor' }
    text { Faker::Lorem.paragraph }
    unknown_content { false }
    broadcasted { false }
    sender { contributors.sample }
    recipient { nil }
    request { requests.sample }
  end
end

Rails.logger.debug 'Seeding messages..'
FactoryBot.build_list(:message, message_count) do |message|
  message.class.skip_callback(:create, :after, :send_if_outbound, raise: false)
  message.save!
end

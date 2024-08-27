# frozen_string_literal: true

require 'factory_bot_rails'
require 'faker'

contributors_count = 30
request_count = 30
replies_count = 30
file_replies_count = 3
photo_replies_count = 3

users = User.all

images = 10.times.map { URI(Faker::Avatar.image(size: '50x50', format: 'png', set: 'set5')) }

FactoryBot.modify do
  factory :contributor do
    organization { Organization.first }
    data_processing_consent { true }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    note { Faker::Movies::HitchhikersGuideToTheGalaxy.quote }

    after(:build) do |contributor|
      image = images.sample
      contributor.avatar.attach(
        io: image.open,
        filename: File.basename(image.path)
      )
    end
  end
end

Rails.logger.debug 'Seeding contributors..'
contributors = FactoryBot.create_list(:contributor, contributors_count)

FactoryBot.modify do
  factory :request do
    organization { Organization.first }
    title { Faker::Lorem.question }
    text { Faker::Lorem.paragraph }
    user { users.sample }
  end
end

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

Rails.logger.debug 'Seeding requests..'
FactoryBot.build_list(:request, request_count) do |request|
  Message.skip_callback(:commit, :after, :send_if_outbound, raise: false)
  request.save!
  Rails.logger.debug 'Seeding requests replies...'
  FactoryBot.create_list(:message, replies_count, request: request)
  FactoryBot.create_list(:message, file_replies_count, :with_file, request: request)
  FactoryBot.create_list(:message, photo_replies_count, :with_a_photo, request: request)
end

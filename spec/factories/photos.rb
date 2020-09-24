# frozen_string_literal: true

FactoryBot.define do
  factory :photo do
    association :message
    image { Rack::Test::UploadedFile.new(Rails.root.join('example-image.png'), 'image/png') }
  end
end

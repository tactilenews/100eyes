# frozen_string_literal: true

FactoryBot.define do
  factory :voice do
    association :message
    attachment { Rack::Test::UploadedFile.new(Rails.root.join('example-audio.oga'), 'audio/ogg') }
  end
end

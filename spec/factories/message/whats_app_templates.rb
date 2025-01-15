# frozen_string_literal: true

FactoryBot.define do
  factory :message_whats_app_template, class: 'Message::WhatsAppTemplate' do
    message { nil }
    external_id { 'MyString' }
  end
end

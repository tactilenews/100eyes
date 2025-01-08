# frozen_string_literal: true

FactoryBot.define do
  factory :organization do
    name { '100eyes' }
    upgrade_discount { 10 }
    project_name { '100eyes' }
    onboarding_title { 'Hallo und herzlich willkommen!' }
    onboarding_page { File.read(File.join('config', 'locales', 'onboarding', 'page.md')) }
    onboarding_success_heading { File.read(File.join('config', 'locales', 'onboarding', 'success_heading.txt')) }
    onboarding_success_text { File.read(File.join('config', 'locales', 'onboarding', 'success_text.txt')) }
    onboarding_data_protection_link { 'https://tactile.news/100eyes-datenschutz/' }
    signal_server_phone_number { Faker::PhoneNumber.unique.cell_phone_in_e164 }
    whats_app_server_phone_number { Faker::PhoneNumber.unique.cell_phone_in_e164 }
    telegram_bot_username { Faker::Internet.unique.username }
    email_from_address { Faker::Internet.email }
    signal_username { Faker::Internet.username(specifier: 3..32, separators: ['_']) }

    transient do
      users_count { 0 }
      contributors_count { 0 }
      business_plan_name { 'Editorial Basic' }
    end

    after(:create) do |org, evaluator|
      if evaluator.users_count.positive?
        org.users << create_list(:user, evaluator.users_count, organizations: [org])
        org.save!
      end
    end

    contributors do
      Array.new(contributors_count) { association(:contributor, organization: instance) }
    end

    business_plan do
      attributes = attributes_for(:business_plan, business_plan_name.downcase.split.join('_').to_sym)
      business_plan = BusinessPlan.create_or_find_by(name: business_plan_name)
      business_plan.update(attributes.merge(valid_from: Time.current, valid_until: Time.current + 6.months))
      business_plan
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Profile' do
  let(:email) { Faker::Internet.safe_email }
  let(:password) { Faker::Internet.password(min_length: 8, max_length: 128) }
  let(:otp_enabled) { true }
  let(:user) do
    create(:user, first_name: 'Daniel', last_name: 'Theis', email: email, password: password, otp_enabled: otp_enabled,
                  organization: organization)
  end
  let(:business_plan) { create(:business_plan) }
  let(:contact_person) { create(:user, first_name: 'Isaac', last_name: 'Bonga') }
  let(:organization) { create(:organization, business_plan: business_plan, contact_person: contact_person) }

  it 'allows viewing/updating business plan' do
    visit profile_path(as: user)

    expect(page).to have_content("Dein 100eyes Plan: \"#{business_plan.name}\"")
    expect(page).to have_content("Auftraggeber:in #{organization.contact_person.name}, #{organization.contact_person.email}")
    expect(page).to have_content("Preis: #{number_to_currency(business_plan.price_per_month)}/Monat")
  end
end

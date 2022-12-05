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
  let(:organization) { create(:organization, business_plan: business_plan, contact_person: contact_person, users_count: 2) }

  it 'allows viewing/updating business plan' do
    visit profile_path(as: user)

    # header
    expect(page).to have_content("Dein 100eyes Plan: \"#{business_plan.name}\"")
    expect(page).to have_content("Auftraggeber:in #{organization.contact_person.name}, #{organization.contact_person.email}")
    expect(page).to have_content("Preis: #{number_to_currency(business_plan.price_per_month)}/Monat")
    expect(page).to have_content("Mindeslaufzeit: bis #{business_plan.valid_until.strftime('%m/%Y')}")
    expect(page).to have_content('Dialogkanäle: Signal, Threema, Telegram, E-mail')
    expect(page).to have_content('Sicherheit: Community abgesichert über Zwei-Faktor-Authentifizierung, Cloudflare')

    # user section
    expect(page).to have_content('Deine Redakteur:Innen')
    expect(page).to have_content("#{organization.users.count} von #{organization.business_plan.number_of_users} Seats genutzt")
    organization.users.each do |user|
      expect(page).to have_content(user.name)
    end
  end
end

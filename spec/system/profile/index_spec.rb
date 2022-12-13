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
  let(:organization) do
    create(:organization, business_plan: business_plan, contact_person: contact_person, users_count: 2, contributors_count: 5)
  end
  let!(:inactive_contributor) { create(:contributor, deactivated_at: 1.hour.ago, organization: organization) }
  before do
    allow(Setting).to receive(:channel_image).and_return(ActiveStorage::Blob.new(filename: 'channel_image.jpg'))
  end

  it 'allows viewing/updating business plan' do
    visit dashboard_path(as: user)

    within('.NavBar') do
      find('a[aria-label="Zur Profilseite"]').click
    end

    expect(page).to have_current_path(profile_path)

    # header
    expect(page).to have_content("Dein 100eyes Plan: \"#{business_plan.name}\"")
    expect(page).to have_content("Auftraggeber:in #{organization.contact_person.name}, #{organization.contact_person.email}")
    expect(page).to have_content("Preis: #{number_to_currency(business_plan.price_per_month)}/Monat")
    expect(page).to have_content("Mindeslaufzeit: bis #{business_plan.valid_until.strftime('%m/%Y')}")
    expect(page).to have_content('Dialogkanäle: Signal, Threema, Telegram, E-mail')
    expect(page).to have_content('Sicherheit: Community abgesichert über Zwei-Faktor-Authentifizierung, Cloudflare')
    click_button('Plan jetzt upgraden')

    # user management section
    expect(page).to have_content('Deine Redakteur:Innen')
    expect(page).to have_content("3 von #{organization.business_plan.number_of_users} Seats genutzt")
    organization.users.each do |user|
      expect(page).to have_content(user.name)
    end
    click_button 'Redakteur:in hinzufügen'
    expect(page).to have_css('.Modal')

    click_button 'Modal schließen'
    expect(page).to have_no_css('.Modal')

    click_button 'Redakteur:in hinzufügen'
    expect(page).to have_css('.Modal')

    within('.Modal') do
      fill_in 'Vorname', with: 'New'
      fill_in 'Nachname', with: 'Editor'
      fill_in 'E-Mail-Adresse', with: 'new-editor@example.org'
      click_button 'Redakteur:in hinzufügen'
    end

    expect(page).to have_no_css('.Modal')
    expect(page).to have_content('Redakteur:in erfolgreich erstellt')
    expect(page).to have_content("4 von #{organization.business_plan.number_of_users} Seats genutzt")
    expect(page).to have_content('New Editor')

    # contributors section
    expect(page).to have_content('Deine Community')
    expect(page).to have_content("5 von #{organization.business_plan.number_of_contributors} Community-Mitglieder aktiv")
    expect(page).to have_css('.ContributorsStatusBar')
    expect(page).to have_css("article[data-contributors-status-bar-contributors-status-value='#{number_with_precision(
      organization.contributors.active.count / organization.business_plan.number_of_contributors.to_f, locale: :en
    )}']")
    expect(page).to have_css("span[style='width: 3.3%;']")
    click_button('Einladungslink generieren')
  end
end

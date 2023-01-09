# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Profile' do
  let(:email) { Faker::Internet.safe_email }
  let(:password) { Faker::Internet.password(min_length: 8, max_length: 128) }
  let(:otp_enabled) { true }
  let(:user) do
    create(:user, first_name: 'Daniel', last_name: 'Theis', email: email, password: password, otp_enabled: otp_enabled)
  end
  let(:current_plan) { business_plans[1] }
  let(:contact_person) { create(:user, first_name: 'Isaac', last_name: 'Bonga') }
  let(:organization) do
    create(:organization, business_plan: current_plan, contact_person: contact_person, contributors_count: 5).tap do |org|
      users = [user, contact_person, create(:user)]
      org.users << users
      org.save!
    end
  end
  let(:business_plans) do
    %i[editorial_basic editorial_pro editorial_enterprise].map do |trait|
      create(:business_plan, trait)
    end
  end
  let!(:inactive_contributor) { create(:contributor, deactivated_at: 1.hour.ago, organization: organization) }
  before do
    allow(Setting).to receive(:channel_image).and_return(ActiveStorage::Blob.new(filename: 'channel_image.jpg'))
    current_plan.update(valid_from: Time.current, valid_until: Time.current + 6.months)
  end

  it 'allows viewing/updating business plan' do
    visit dashboard_path(as: user)

    within('.NavBar') do
      find('a[aria-label="Zur Profilseite"]').click
    end

    expect(page).to have_current_path(profile_path)

    # header
    expect(page).to have_content("Dein 100eyes Plan: \"#{current_plan.name}\"")
    expect(page).to have_content("Auftraggeber:in #{organization.contact_person.name}, #{organization.contact_person.email}")
    expect(page).to have_content("Preis: #{number_to_currency(current_plan.price_per_month)}/Monat")
    expect(page).to have_content("Mindeslaufzeit: bis #{current_plan.valid_until.strftime('%m/%Y')}")
    expect(page).to have_content('Dialogkanäle: Signal, Threema, Telegram, E-mail')
    expect(page).to have_content('Sicherheit: Community abgesichert über Zwei-Faktor-Authentifizierung, Cloudflare')

    click_button("Plan jetzt upgraden und #{organization.upgrade_discount}% sparen")
    expect(page).to have_css('.UpgradeBusinessPlanModal')

    click_button 'Modal schließen'
    expect(page).to have_no_css('.UpgradeBusinessPlanModal')

    # user management section
    expect(page).to have_content('Deine Redakteur:Innen')
    expect(page).to have_content("3 von #{current_plan.number_of_users} Seats genutzt")
    organization.users.each do |user|
      expect(page).to have_content(user.name)
    end
    click_button 'Redakteur:in hinzufügen'
    expect(page).to have_css('.CreateUserModal')

    click_button 'Modal schließen'
    expect(page).to have_no_css('.CreateUserModal')

    # contributors section
    expect(page).to have_content('Deine Community')
    expect(page).to have_content("5 von #{current_plan.number_of_contributors} Community-Mitglieder aktiv")
    expect(page).to have_css('.ContributorsStatusBar')
    expect(page).to have_css("article[data-contributors-status-bar-contributors-status-value='#{number_with_precision(
      organization.contributors.active.count / current_plan.number_of_contributors.to_f, locale: :en
    )}']")
    expect(page).to have_css("span[style='width: 3.3%;']")
    click_button('Einladungslink generieren')

    # Create users

    click_button 'Redakteur:in hinzufügen'
    expect(page).to have_css('.CreateUserModal')

    within('.CreateUserModal') do
      fill_in 'Vorname', with: 'New'
      fill_in 'Nachname', with: 'Editor'
      fill_in 'E-Mail-Adresse', with: email
      click_button 'Redakteur:in hinzufügen'
    end

    expect(page).to have_content('Email ist bereits vergeben')

    click_button 'Redakteur:in hinzufügen'
    expect(page).to have_css('.CreateUserModal')

    within('.CreateUserModal') do
      fill_in 'Vorname', with: 'New'
      fill_in 'Nachname', with: 'Editor'
      fill_in 'E-Mail-Adresse', with: 'new-editor@example.org'
      click_button 'Redakteur:in hinzufügen'
    end

    expect(page).to have_no_css('.CreateUserModal')
    expect(page).to have_content('Redakteur:in erfolgreich erstellt')
    expect(page).to have_content("4 von #{current_plan.number_of_users} Seats genutzt")
    expect(page).to have_content('New Editor')

    # Upgrade BusinessPlan

    click_button("Plan jetzt upgraden und #{organization.upgrade_discount}% sparen")
    expect(page).to have_css('.UpgradeBusinessPlanModal')

    within('.UpgradeBusinessPlanModal') do
      business_plans.each do |bp|
        expect(find("input[id='#{bp.id}'")).to be_disabled if bp.price_per_month < current_plan.price_per_month
        expect(page).to have_content(bp.name)
        expect(page).to have_content(
          "#{bp.number_of_communities} Gemeinschaft mit #{bp.number_of_users} Benutzern und #{bp.number_of_contributors} Mitwirkenden."
        )
        expect(page).to have_content("Inklusive #{bp.hours_of_included_support} Stunden Support") if bp.hours_of_included_support > 0
        expect(page).to have_content("#{number_to_currency(bp.price_per_month)}/Monat")
      end
      find('label[aria-label="Editorial enterprise"]').click
      click_button 'Upgrade Plan'
    end
    editorial_enterprise = business_plans[2]
    expect(page).to have_no_css('.UpgradeBusinessPlanModal')
    expect(page).to have_content('Plan erfolgreich aktualisiert')
    expect(page).to have_content("Dein 100eyes Plan: \"#{editorial_enterprise.name}\"")
    expect(page).to have_content("Preis: #{number_to_currency(editorial_enterprise.price_per_month)}/Monat")
    # no plans to upgrade to
    expect(page).not_to have_button("Plan jetzt upgraden und #{organization.upgrade_discount}% sparen")
    # takes over the valid_until from current_plan
    expect(page).to have_content("Mindeslaufzeit: bis #{current_plan.valid_until.strftime('%m/%Y')}")
  end
end

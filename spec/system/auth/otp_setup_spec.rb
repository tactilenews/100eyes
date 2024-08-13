# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'OTP Setup' do
  let(:organization) { create(:organization) }
  let(:email) { Faker::Internet.email }
  let(:password) { Faker::Internet.password(min_length: 8, max_length: 128) }
  let(:new_password) { Faker::Internet.password(min_length: 8, max_length: 128) }
  let(:otp_enabled) { true }
  let(:user) { create(:user, email: email, password: password, otp_enabled: otp_enabled, organizations: [organization]) }

  describe 'without 2FA set up' do
    let(:otp_enabled) { false }

    it 'editor tries to access any page' do
      visit organization_dashboard_path(organization, as: user)

      expect(page).to have_current_path(otp_setup_path)
      expect(page).to have_text('Schütze dein Konto')

      # Editor enters incorrect OTP
      fill_in 'setup[otp]', with: user.otp_code.reverse
      click_button 'Bestätigen'

      expect(page).to have_current_path(otp_setup_path)

      # Editor enters correct code
      fill_in 'setup[otp]', with: user.otp_code

      expect { click_button 'Bestätigen' }.not_to(change { user.reload.otp_secret_key })

      # Editor is redirected back to the dashboard
      expect(page).to have_current_path(organization_dashboard_path(organization))
    end

    it 'editor cancels setup' do
      visit organization_dashboard_path(organization, as: user)

      expect(page).to have_current_path(otp_setup_path)
      expect(page).to have_text('Schütze dein Konto')

      click_link 'Abbrechen'

      expect(page).to have_current_path(sign_in_path)
    end
  end

  describe 'with 2FA set up' do
    let(:otp_enabled) { true }

    it 'editor tries to access any page' do
      visit organization_dashboard_path(organization, as: user)

      # Editor is not redirected
      expect(page).to have_current_path(organization_dashboard_path(organization), ignore_query: true)
    end

    it 'editor tries to access setup page' do
      visit otp_setup_path(as: user)

      expect(page).to have_current_path(organization_dashboard_path(organization))
    end
  end
end

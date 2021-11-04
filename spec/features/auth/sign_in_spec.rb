# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Sign in', type: :feature do
  let(:email) { 'zora@example.org' }
  let(:password) { '12345678' }
  let(:otp_enabled) { true }
  let!(:user) { create(:user, email: email, password: password, otp_enabled: otp_enabled) }

  scenario 'editor tries to visit protected page' do
    visit dashboard_path
    expect(page).to have_current_path(sign_in_path)
  end

  context 'without 2FA set up' do
    let(:otp_enabled) { false }

    scenario 'editor signs in' do
      visit sign_in_path

      # Enter incorrect credentials
      fill_in 'session[email]', with: 'zora@example.org'
      fill_in 'session[password]', with: 'abcdefgh'
      click_button 'Anmelden'

      expect(page).to have_current_path(session_path)
      expect(page).to have_text('E-Mail oder Passwort ungültig.')

      # Enters correct credentials
      fill_in 'session[email]', with: 'zora@example.org'
      fill_in 'session[password]', with: '12345678'
      click_button 'Anmelden'

      # User is redirected to set up 2FA
      expect(page).to have_current_path(otp_setup_path)
    end
  end

  context 'with 2FA set up' do
    let(:otp_enabled) { true }

    scenario 'editor signs in' do
      visit sign_in_path

      # Enter incorrect credentials
      fill_in 'session[email]', with: 'zora@example.org'
      fill_in 'session[password]', with: 'abcdefgh'
      click_button 'Anmelden'

      expect(page).to have_current_path(session_path)
      expect(page).to have_text('E-Mail oder Passwort ungültig.')

      # Enters correct credentials
      fill_in 'session[email]', with: 'zora@example.org'
      fill_in 'session[password]', with: '12345678'
      click_button 'Anmelden'

      expect(page).to have_current_path(otp_auth_path)
      expect(page).to have_text('Anmeldung bestätigen')

      # Enters wrong code
      fill_in 'session[otp]', with: user.otp_code.reverse
      click_button 'Bestätigen'

      expect(page).to have_current_path(otp_auth_path)
      expect(page).to have_text('Der 6-stellige Anmeldecode ist nicht korrekt.')

      # Enters correct code
      fill_in 'session[otp]', with: user.otp_code
      click_button 'Bestätigen'

      # User is redirected to dashboard
      expect(page).to have_current_path(dashboard_path)
    end

    scenario 'editor cancels sign in' do
      visit sign_in_path

      # Sign in
      fill_in 'session[email]', with: email
      fill_in 'session[password]', with: password
      click_button 'Anmelden'

      # User is prompted to provide OTP
      expect(page).to have_current_path(otp_auth_path)
      expect(page).to have_text('Anmeldung bestätigen')

      click_link 'Abbrechen'

      expect(page).to have_current_path(sign_in_path)
    end

    scenario 'signed-in editor visits OTP page' do
      visit otp_auth_path(as: user)

      expect(page).to have_current_path(dashboard_path)
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Sign in', type: :feature do
  let(:email) { Faker::Internet.safe_email }
  let(:password) { Faker::Internet.password(min_length: 8, max_length: 128) }
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

      fill_in 'session[email]', with: email
      fill_in 'session[password]', with: password

      click_button 'Anmelden'

      # User is redirected to set up 2FA
      expect(page).to have_current_path(new_otp_setup_path)
    end
  end

  context 'with 2FA set up' do
    let(:otp_enabled) { true }

    scenario 'editor signs in' do
      visit sign_in_path

      fill_in 'session[email]', with: email
      fill_in 'session[password]', with: password
      click_button 'Anmelden'

      expect(page).to have_current_path(new_otp_confirmation_path)
      expect(page).to have_text('Anmeldung bestätigen')

      # Enters wrong code
      fill_in 'session[otp]', with: user.otp_code.reverse
      click_button 'Bestätigen'

      expect(page).to have_current_path(otp_confirmation_path)
      expect(page).to have_text('Der 6-stellige Anmeldecode ist nicht korrekt.')

      # Enters correct code
      fill_in 'session[otp]', with: user.otp_code
      click_button 'Bestätigen'

      # User is redirected to dashboard
      expect(page).to have_current_path(dashboard_path)
    end

    scenario 'editor signs out and in again' do
      visit sign_in_path

      # Sign in
      fill_in 'session[email]', with: email
      fill_in 'session[password]', with: password
      click_button 'Anmelden'

      fill_in 'session[otp]', with: user.otp_code
      click_button 'Bestätigen'

      # Sign out
      click_link 'Abmelden'

      # Sign in again
      fill_in 'session[email]', with: email
      fill_in 'session[password]', with: password
      click_button 'Anmelden'

      # User has to provide OTP code again
      expect(page).to have_current_path(new_otp_confirmation_path)
      expect(page).to have_text('Anmeldung bestätigen')

      fill_in 'session[otp]', with: user.otp_code
      click_button 'Bestätigen'

      expect(page).to have_current_path(dashboard_path)
    end

    scenario 'editor tries to circumvent otp verification' do
      visit sign_in_path

      # Sign in
      fill_in 'session[email]', with: email
      fill_in 'session[password]', with: password
      click_button 'Anmelden'

      # User is prompted to provide OTP
      expect(page).to have_current_path(new_otp_confirmation_path)
      expect(page).to have_text('Anmeldung bestätigen')

      # Editor tries to visit dashboard directly
      visit dashboard_path

      # Editor is again prompted to confirm OTP
      expect(page).to have_current_path(new_otp_confirmation_path)
      expect(page).to have_text('Anmeldung bestätigen')
    end

    scenario 'editor cancel sign in' do
      visit sign_in_path

      # Sign in
      fill_in 'session[email]', with: email
      fill_in 'session[password]', with: password
      click_button 'Anmelden'

      # User is prompted to provide OTP
      expect(page).to have_current_path(new_otp_confirmation_path)
      expect(page).to have_text('Anmeldung bestätigen')

      click_link 'Abbrechen'

      expect(page).to have_current_path(sign_in_path)
    end

    scenario 'editor visit OTP confirmation page' do
      visit new_otp_confirmation_path(as: user)

      expect(page).to have_current_path(dashboard_path)
    end
  end
end

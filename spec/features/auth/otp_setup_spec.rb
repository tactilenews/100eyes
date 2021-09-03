# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'OTP Setup', type: :feature do
  let(:email) { Faker::Internet.safe_email }
  let(:password) { Faker::Internet.password(min_length: 8, max_length: 128) }
  let(:new_password) { Faker::Internet.password(min_length: 8, max_length: 128) }
  let(:otp_enabled) { true }
  let(:user) { create(:user, email: email, password: password, otp_enabled: otp_enabled) }

  context 'without 2FA set up' do
    let(:otp_enabled) { false }

    scenario 'editor tries to access any page' do
      visit dashboard_path(as: user)

      expect(page).to have_current_path(new_otp_setup_path)
      expect(page).to have_text('Dein Konto absichern')

      # Editor enters incorrect OTP
      fill_in 'setup[otp]', with: user.otp_code.reverse
      click_button 'Bestätigen'

      expect(page).to have_current_path(otp_setup_path)

      # Editor enters correct code
      fill_in 'setup[otp]', with: user.otp_code
      click_button 'Bestätigen'

      # Editor is redirected back to the dashboard
      expect(page).to have_current_path(dashboard_path)
    end

    scenario 'editor cancels setup' do
      visit dashboard_path(as: user)

      expect(page).to have_current_path(new_otp_setup_path)
      expect(page).to have_text('Dein Konto absichern')

      click_link 'Abbrechen'

      expect(page).to have_current_path(sign_in_path)
    end
  end

  context 'with 2FA set up' do
    let(:otp_enabled) { true }

    scenario 'editor tries to access page' do
      visit dashboard_path(as: user)

      # Editor has to confirm OTP, but is not prompted to
      # set up 2FA
      expect(page).to have_current_path(new_otp_confirmation_path)
      fill_in 'session[otp]', with: user.otp_code
      click_button 'Bestätigen'

      expect(page).to have_current_path(dashboard_path)
    end
  end
end

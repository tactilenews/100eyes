# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Password Reset', type: :feature do
  let(:email) { Faker::Internet.safe_email }
  let(:password) { Faker::Internet.password(min_length: 8, max_length: 128) }
  let(:new_password) { Faker::Internet.password(min_length: 8, max_length: 128) }
  let!(:user) { create(:user, email: email, password: password, otp_enabled: otp_enabled) }

  context 'without 2FA set up' do
    let(:otp_enabled) { false }

    scenario 'editor resets password' do
      visit new_password_path

      fill_in 'E-Mail', with: email
      click_button 'Passwort ändern'

      visit edit_user_password_path(user_id: user.id, token: user.reload.confirmation_token)

      fill_in 'password_reset[password]', with: new_password
      click_button 'Passwort ändern'

      # Editor is not signed-in automatically
      expect(page).to have_current_path(sign_in_path)
    end
  end

  context 'with 2FA set up' do
    let(:otp_enabled) { true }

    scenario 'editor resets password' do
      visit new_password_path

      fill_in 'E-Mail', with: email
      click_button 'Passwort ändern'

      visit edit_user_password_path(user_id: user.id, token: user.reload.confirmation_token)

      expect(page).to have_text('Passwort ändern')
      fill_in 'password_reset[password]', with: new_password
      click_button 'Passwort ändern'

      # Editor is not signed-in automatically
      expect(page).to have_current_path(sign_in_path)
    end
  end
end

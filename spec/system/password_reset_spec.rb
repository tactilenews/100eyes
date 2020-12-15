# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Password Reset' do
  context 'Valid' do
    let!(:user) { create(:user, email: email) }
    let(:email) { Faker::Internet.safe_email }
    let(:password) { Faker::Internet.safe_email }

    it 'Redirects to dashboard after verifying otp_code' do
      visit '/dashboard'

      expect(page).to have_current_path('/sign_in')

      click_link I18n.t('sessions.form.link_text')
      expect(page).to have_current_path('/passwords/new')

      fill_in I18n.t('helpers.label.password.email'), with: email
      click_button I18n.t('helpers.submit.password_reset.submit')

      expect(page).to have_current_path('/passwords')
      expect(page).to have_content(I18n.t('passwords.create.description'))
      visit "/users/#{user.id}/password/edit?token=#{user.reload.confirmation_token}"

      expect(page).to have_content(I18n.t('passwords.edit.title'))
      fill_in I18n.t('helpers.label.password_reset.password'), with: password

      # Since this input does not have a id, we cannot use fill_in with the label, name, id
      find('input[data-target="password-reset-form.passwordConfirmation"]').set(password)
      click_button I18n.t('helpers.submit.password_reset.submit')

      expect(page).to have_content(I18n.t('user.sign_in.two_factor_authentication.header'))

      fill_in I18n.t('user.sign_in.two_factor_authentication.label'), with: user.otp_code
      click_button I18n.t('user.sign_in.two_factor_authentication.submit')

      expect(page).to have_current_path('/dashboard')
      expect(page).to have_button(I18n.t('components.nav_bar.sign_out'))
    end
  end
end

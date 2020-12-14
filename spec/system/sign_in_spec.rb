# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Sign in' do
  context 'Valid' do
    let(:user) { create(:user, email: email, password: password) }
    let(:email) { Faker::Internet.safe_email }
    let(:password) { Faker::Internet.password(min_length: 20, max_length: 128) }

    it 'Redirects to dashboard on successful login' do
      visit '/dashboard'

      expect(page).to have_current_path('/sign_in')

      fill_in I18n.t('helpers.label.password.email'), with: user.email
      fill_in I18n.t('helpers.label.session.password'), with: user.password
      click_button I18n.t('helpers.submit.session.submit')

      expect(page).to have_current_path('/session/verify_user_email_and_password')
      expect(page).to have_css('svg')

      fill_in I18n.t('helpers.label.session.password'), with: user.otp_code
      click_button I18n.t('user.sign_in.two_factor_authentication.submit')

      expect(page).to have_current_path('/dashboard')
      expect(page).to have_button(I18n.t('components.nav_bar.sign_out'))
    end
  end
end

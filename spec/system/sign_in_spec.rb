# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Sign in' do
  context 'Valid' do
    let(:email) { Faker::Internet.safe_email }
    let(:password) { Faker::Internet.password(min_length: 20, max_length: 128) }

    context 'otp_enabled? false' do
      let(:user) { create(:user, email: email, password: password, otp_enabled: false) }

      before do
        visit dashboard_path

        expect(page).to have_current_path('/sign_in')

        fill_in 'E-Mail', with: user.email
        fill_in 'Passwort', with: user.password
        click_button 'Anmelden'

        expect(page).to have_current_path(two_factor_auth_setup_user_setting_path(user))
      end

      describe 'following links to protected pages' do
        it 'redirects to user setting page to enable 2fa' do
          # Does not allow to use site without enabling otp
          click_link I18n.t('setting.setting.other')
          expect(page).to have_current_path(two_factor_auth_setup_user_setting_path(user))

          click_link I18n.t('application_name')
          expect(page).to have_current_path(two_factor_auth_setup_user_setting_path(user))
          expect(page).to have_css('svg')
        end
      end

      describe 'entering invalid 2FA token' do
        it 'redirects to dashboard path' do
          fill_in I18n.t('two_factor_authentication.otp_code.label'), with: '123456'
          click_button I18n.t('two_factor_authentication.otp_code.submit')

          expect(page).to have_current_path(two_factor_auth_setup_user_setting_path(user))

          fill_in I18n.t('two_factor_authentication.otp_code.label'), with: '123456'
          click_button I18n.t('two_factor_authentication.otp_code.submit')

          expect(page).to have_current_path(two_factor_auth_setup_user_setting_path(user))
        end
      end

      describe 'entering valid 2FA token' do
        it 'redirects to dashboard path' do
          fill_in I18n.t('two_factor_authentication.otp_code.label'), with: user.otp_code
          click_button I18n.t('two_factor_authentication.otp_code.submit')

          expect(page).to have_current_path(dashboard_path)
          expect(page).to have_link(I18n.t('components.nav_bar.sign_out'))
          expect(page).to have_content(I18n.t('dashboard.how_it_works'))
        end
      end
    end

    context 'otp_enabled? true' do
      let(:user) { create(:user, email: email, password: password) }

      it 'Redirects to dashboard on successful sign in' do
        visit dashboard_path

        expect(page).to have_current_path('/sign_in')

        fill_in 'E-Mail', with: user.email
        fill_in 'Passwort', with: user.password
        fill_in '6-stelliger Anmeldecode', with: user.otp_code

        click_button 'Anmelden'

        expect(page).to have_current_path(dashboard_path)
        expect(page).to have_link(I18n.t('components.nav_bar.sign_out'))
        expect(page).to have_content(I18n.t('dashboard.how_it_works'))
      end
    end
  end
end

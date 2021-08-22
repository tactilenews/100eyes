# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Password Reset' do
  context 'Valid' do
    let!(:user) { create(:user, email: email, otp_enabled: false) }
    let(:email) { Faker::Internet.safe_email }
    let(:password) { Faker::Internet.password(min_length: 20, max_length: 128) }

    context 'otp_enabled? false' do
      it 'Redirects to user setting page to enable 2fa' do
        visit '/dashboard'

        expect(page).to have_current_path('/sign_in')

        click_link 'Passwort vergessen?'
        expect(page).to have_current_path('/passwords/new')

        fill_in 'E-Mail', with: email
        click_button 'Passwort ändern'

        expect(page).to have_current_path('/passwords')
        expect(page).to have_content('Wir haben dir eine E-Mail gesendet.')
        visit "/users/#{user.id}/password/edit?token=#{user.reload.confirmation_token}"

        expect(page).to have_content('Passwort ändern')
        fill_in 'Passwort', with: password
        click_button 'Passwort ändern'

        expect(page).to have_current_path(two_factor_auth_setup_user_setting_path(user))

        # Does not allow to use site without enabling otp
        click_link I18n.t('setting.setting.other')
        expect(page).to have_current_path(two_factor_auth_setup_user_setting_path(user))

        click_link I18n.t('application_name')
        expect(page).to have_current_path(two_factor_auth_setup_user_setting_path(user))
        expect(page).to have_css('svg')

        fill_in I18n.t('two_factor_authentication.otp_code.label'), with: user.otp_code
        click_button I18n.t('two_factor_authentication.otp_code.submit')

        expect(page).to have_current_path(dashboard_path)
        expect(page).to have_link(I18n.t('components.nav_bar.sign_out'))
        expect(page).to have_content(I18n.t('dashboard.how_it_works'))
      end
    end

    context 'otp_enabled? true' do
      let!(:user) { create(:user, email: email) }

      it 'Redirects to dashboard after verifying otp_code' do
        visit '/dashboard'

        expect(page).to have_current_path('/sign_in')

        click_link 'Passwort vergessen?'
        expect(page).to have_current_path('/passwords/new')

        fill_in 'E-Mail', with: email
        click_button 'Passwort ändern'

        expect(page).to have_current_path('/passwords')
        expect(page).to have_content('Wir haben dir eine E-Mail gesendet.')
        visit "/users/#{user.id}/password/edit?token=#{user.reload.confirmation_token}"

        expect(page).to have_content('Passwort ändern')
        fill_in 'Passwort', with: password

        fill_in '6-stelliger Anmeldecode', with: user.otp_code

        click_button 'Passwort ändern'

        expect(page).to have_current_path('/dashboard')
        expect(page).to have_link(I18n.t('components.nav_bar.sign_out'))
        expect(page).to have_content(I18n.t('dashboard.how_it_works'))
      end
    end
  end
end

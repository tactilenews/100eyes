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

        expect(page).to have_current_path(two_factor_auth_setup_user_setting_path(user))

        # Does not allow to use site without enabling otp
        click_link I18n.t('setting.setting.other')
        expect(page).to have_current_path(two_factor_auth_setup_user_setting_path(user))

        click_link I18n.t('application_name')
        expect(page).to have_current_path(two_factor_auth_setup_user_setting_path(user))
        expect(page).to have_css('svg')

        fill_in I18n.t('user.form.otp_code.label'), with: user.otp_code
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

        fill_in I18n.t('user.form.otp_code.label'), with: user.otp_code

        click_button I18n.t('helpers.submit.password_reset.submit')

        expect(page).to have_current_path('/dashboard')
        expect(page).to have_link(I18n.t('components.nav_bar.sign_out'))
        expect(page).to have_content(I18n.t('dashboard.how_it_works'))
      end
    end
  end
end

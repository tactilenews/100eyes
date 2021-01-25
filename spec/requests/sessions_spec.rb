# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Sessions' do
  describe 'POST /session' do
    subject { post '/session', params: params }

    let(:params) do
      { session: { email: email, password: password, otp_code: otp_code } }
    end
    let(:email) { Faker::Internet.safe_email }
    let(:password) { Faker::Internet.password(min_length: 20, max_length: 128) }
    let(:otp_code) { nil }

    context "User doesn't exist" do
      before { subject }

      it 'is unauthorized' do
        expect(response).to be_unauthorized
      end

      it 'displays error message, but does not give off if a user with email exists' do
        expect(response.request.flash[:alert]).to eq(I18n.t('flashes.failure_after_create'))
      end
    end

    context 'User exists' do
      let(:valid_email) { Faker::Internet.safe_email }
      let(:valid_password) { Faker::Internet.password(min_length: 20, max_length: 128) }
      let!(:user) { create(:user, email: valid_email, password: valid_password) }
      let(:otp_code) { user.otp_code }

      context 'Incorrect email' do
        let(:email) { Faker::Internet.safe_email }
        let(:password) { valid_password }

        before { subject }

        it 'is unauthorized' do
          expect(response).to be_unauthorized
        end

        it 'displays error message, but does not give off if a user with email exists' do
          expect(response.request.flash[:alert]).to eq(I18n.t('flashes.failure_after_create'))
        end
      end

      context 'Incorrect password' do
        let(:password) { Faker::Internet.password(min_length: 20, max_length: 128) }
        let(:email) { valid_email }

        before { subject }

        it 'is unauthorized' do
          expect(response).to be_unauthorized
        end

        it 'displays error message, but does not give off if a user with email exists' do
          expect(response.request.flash[:alert]).to eq(I18n.t('flashes.failure_after_create'))
        end
      end

      context 'Incorrect otp_code' do
        let(:otp_code) { '123456' }

        before { subject }

        it 'is unauthorized' do
          expect(response).to be_unauthorized
        end

        it 'displays error message, but does not give off if a user with email exists' do
          expect(response.request.flash[:alert]).to eq(I18n.t('flashes.failure_after_create'))
        end
      end

      context 'Correct email/password combination' do
        let(:email) { valid_email }
        let(:password) { valid_password }

        context 'otp_enabled? false' do
          before { user.update(otp_enabled: false) }

          it 'allows signing in without code, but redirects to user settings to set up 2fa' do
            subject
            expect(response).to redirect_to(dashboard_path)

            follow_redirect!
            expect(response).to redirect_to(two_factor_auth_setup_user_setting_path(user))
          end
        end

        context 'otp_enabled? true' do
          before { subject }
          let(:otp_code) { user.otp_code }

          it 'redirects to the dashboard' do
            expect(response).to redirect_to(dashboard_path)
          end
        end
      end
    end
  end
end

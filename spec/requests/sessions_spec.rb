# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Sessions' do
  describe 'POST /session/verify_user_email_and_password' do
    subject { post '/session/verify_user_email_and_password', params: params }

    let(:params) do
      { session: { email: email, password: password } }
    end

    context "User doesn't exist" do
      let(:email) { Faker::Internet.safe_email }
      let(:password) { Faker::Internet.password(min_length: 20, max_length: 128) }
      before { subject }

      it 'Redirects' do
        expect(response).to redirect_to('/sign_in')
      end

      it 'displays error message' do
        expect(response.request.flash[:error]).to eq(I18n.t('flashes.failure_after_create'))
      end
    end

    context 'User exists' do
      let(:valid_email) { Faker::Internet.safe_email }
      let(:valid_password) { Faker::Internet.password(min_length: 20, max_length: 128) }
      let!(:user) { create(:user, email: valid_email, password: valid_password) }

      context 'Incorrect email' do
        let(:email) { Faker::Internet.safe_email }
        let(:password) { valid_password }

        before { subject }

        it 'Redirects' do
          expect(response).to redirect_to('/sign_in')
        end

        it 'displays error message' do
          expect(response.request.flash[:error]).to eq(I18n.t('flashes.failure_after_create'))
        end
      end

      context 'Incorrect password' do
        let(:password) { Faker::Internet.password(min_length: 20, max_length: 128) }
        let(:email) { valid_email }

        before { subject }

        it 'Redirects' do
          expect(response).to redirect_to('/sign_in')
        end

        it 'displays error message' do
          expect(response.request.flash[:error]).to eq(I18n.t('flashes.failure_after_create'))
        end
      end

      context 'Correct email/password combination' do
        let(:cookie_jar) { ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash) }
        let(:rqr_code) { instance_double(RQRCode::QRCode, as_svg: '<svg></svg>') }
        let(:email) { valid_email }
        let(:password) { valid_password }

        
        context "otp_enabled? true" do
          before { subject }

          it 'Is successful' do
            expect(response).to be_successful
          end
  
          it 'Sets encrypted cookie to store user_id' do
            expect(cookie_jar.encrypted['sessions_user_id']).to eq(user.id)
          end
        end

        context "otp_enabled? false" do
          before { user.update(otp_enabled: false) }

          it "redirects to user settings to set up 2fa" do
            subject
            expect(response).to redirect_to(dashboard_path)

            follow_redirect!
            expect(response).to redirect_to(two_factor_auth_setup_user_setting_path(user))
          end
        end
      end
    end
  end

  describe 'PATCH /session/verify_user_otp' do
    subject { patch '/session/verify_user_otp', params: { session: { otp_code_token: otp_code_token } } }

    let(:otp_code_token) { SecureRandom.hex(3) }

    context 'No user' do
      it 'returns status unauthorized, but does not reveal whether a user exists or not' do
        subject
        expect(response).to be_unauthorized
      end
    end

    context 'User exists' do
      let(:user) { create(:user) }

      before do
        my_cookies = ActionDispatch::Request.new(Rails.application.env_config.deep_dup).cookie_jar
        my_cookies.encrypted[:sessions_user_id] = { value: user.id, expires: 3.minutes }
        cookies[:sessions_user_id] = my_cookies[:sessions_user_id]
      end

      context 'Unauthorized' do
        before { subject }
       
        it 'Invalid otp_code' do
          expect(response).to be_unauthorized
        end
    
        it 'displays error message' do
          expect(response.request.flash[:error]).to eq(I18n.t('components.two_factor_authentication.failure_message'))
        end
      end
  
      context 'Authorized' do
        let(:otp_code_token) { user.otp_code }
  
        it 'valid otp_code' do
          subject
          expect(response).to redirect_to('/dashboard')
        end
  
        it 'sets remember_token for user' do
          subject
          expect(response.cookies['remember_token']).to eq(user.remember_token)
        end
      end
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Sessions' do
  describe 'POST /session/verify_user_email_and_password' do
    subject { post '/session/verify_user_email_and_password', params: { session: { email: email, password: password } } }
    
    let(:email) { Faker::Internet.safe_email }
    let(:password) { Faker::Internet.password(min_length: 20, max_length: 128) }

    context "User doesn't exist" do

      before { subject } 

      it "Redirects" do
        expect(response).to redirect_to('/sign_in')
      end

      it "displays error message" do
        expect(response.request.flash[:error]).to eq(I18n.t('flashes.failure_after_create'))
      end
    end

    context "User exists" do
      let!(:user) { create(:user, email: email, password: password) }

      # before { subject } 

      context "Incorrect email" do
        let(:email) { Faker::Internet.safe_email }

        it "Redirects" do
          expect(response).to redirect_to('/sign_in')
        end

        it "displays error message" do
          expect(response.request.flash[:error]).to eq(I18n.t('flashes.failure_after_create'))
        end
      end

      context "Incorrect password" do
        let(:password) { Faker::Internet.password(min_length: 20, max_length: 128) }

        it "Redirects" do
          expect(response).to redirect_to('/sign_in')
        end

        it "displays error message" do
          expect(response.request.flash[:error]).to eq(I18n.t('flashes.failure_after_create'))
        end
      end

      context "Correct email/password combination" do
        let(:cookie_jar) { ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash) }
        let(:rqr_code) { instance_double(RQRCode::QRCode, as_svg: "<svg></svg>") }
        
        before do
          allow(RQRCode::QRCode).to receive(:new).and_return(rqr_code)
        end
        
        it "Is successful" do
          expect(response).to be_successful
        end

        it "Sets encrypted cookie to store user_id" do
          expect(cookie_jar.encrypted['sessions_user_id']).to eq(user.id)
        end

        it "creates a rqr code with the user provisioning_uri and project name" do
          expect(RQRCode::QRCode).to receive(:new).with(user.provisioning_uri(Setting.project_name))
          
          subject
        end
      end
    end
  end
end

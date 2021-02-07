# frozen_string_literal: true

require 'rails_helper'
require 'telegram/bot/rspec/integration/rails'

RSpec.describe 'Onboarding::Telegram', type: :request do
  let(:contributor) { create(:contributor) }
  let(:jwt) { JsonWebToken.encode({ invite_code: 'ONBOARDING_TOKEN', action: 'onboarding' }) }
  let(:params) { { jwt: jwt } }

  describe 'GET /onboarding/telegram/create' do
    let(:today) { Time.zone.now }
    let(:hash_created_at) { Time.new(today.year, today.month, today.day).to_i }
    let(:valid_hash) do
      check_string = auth_data.map { |k, v| "#{k}=#{v}" }.sort.join("\n")
      secret_key = OpenSSL::Digest.new('SHA256').digest(Setting.telegram_bot_api_key)
      OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), secret_key, check_string)
    end
    let(:auth_data) do
      {
        id: 123,
        auth_date: hash_created_at,
        first_name: 'Matthew',
        last_name: 'Rider',
        username: 'matthew_rider',
        photo_url: 'https://t.me/i/userpic/320/eV9Evr8bcuIEafRdet7x-MOBNs9cTcJU9mMBHIjWi64.jpg'
      }
    end
    let(:params) do
      auth_data.merge(
        hash: valid_hash,
        jwt: jwt
      )
    end

    subject { -> { get onboarding_telegram_path(**params) } }

    context 'invalid' do
      it 'if the hash does not match' do
        params[:hash] = 'I was not created with your api key'
        expect { subject.call }.to raise_exception(ActionController::BadRequest)
      end

      it 'if the id is different' do
        params[:id] = 345
        expect { subject.call }.to raise_exception(ActionController::BadRequest)
      end

      it 'if the first name is different' do
        params[:first_name] = 'different'
        expect { subject.call }.to raise_exception(ActionController::BadRequest)
      end

      it 'if the last name is different' do
        params[:last_name] = 'different'
        expect { subject.call }.to raise_exception(ActionController::BadRequest)
      end

      it 'if the username is different' do
        params[:username] = 'different'
        expect { subject.call }.to raise_exception(ActionController::BadRequest)
      end

      it 'if the photo url is different' do
        params[:photo_url] = 'https://different.jpg'
        expect { subject.call }.to raise_exception(ActionController::BadRequest)
      end

      it 'if the auth_date is greater than one day' do
        params[:auth_date] = (Time.zone.now - 1.day).to_i
        expect { subject.call }.to raise_exception(ActionController::BadRequest)
      end
    end

    context 'valid' do
      it { is_expected.not_to raise_exception }
      it { is_expected.to change(Contributor, :count).by(1) }

      it 'is successful' do
        subject.call
        expect(response).to be_successful
      end

      it 'invalidates the jwt' do
        expect { subject.call }.to change(JsonWebToken, :count).by(1)

        json_web_token = JsonWebToken.where(invalidated_jwt: jwt)
        expect(json_web_token).to exist
      end

      context 'sets an encrypted cookie' do
        let(:cookie_jar) { ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash) }

        it 'with telegram_id for use in next step' do
          subject.call
          expect(cookie_jar.encrypted['telegram_id']).to eq(123)
        end
      end
    end

    describe 'given an existing telegram id' do
      let(:attrs) do
        {
          first_name: 'Tom',
          last_name: 'Jones',
          telegram_id: 123
        }
      end
      let!(:contributor) { create(:contributor, **attrs) }

      it 'redirects to success page' do
        subject.call
        expect(response).to redirect_to onboarding_success_path
      end

      it 'invalidates the jwt' do
        expect { subject.call }.to change(JsonWebToken, :count).by(1)

        json_web_token = JsonWebToken.where(invalidated_jwt: jwt)
        expect(json_web_token).to exist
      end

      it 'does not create new contributor' do
        expect { subject.call }.not_to change(Contributor, :count)
      end
    end
  end

  describe 'PATCH /onboarding/telegram/update' do
    let!(:contributor) { create(:contributor, telegram_id: 789, first_name: nil, last_name: nil) }
    let(:attrs) do
      {
        first_name: 'Update',
        last_name: 'MyNames'
      }
    end
    let(:params) { { jwt: jwt, contributor: attrs } }
    subject { -> { patch onboarding_telegram_path, params: params } }

    context 'invalid' do
      context 'no telegram id in cookie' do
        before { subject.call }

        it 'is unauthorized' do
          expect(response).to be_unauthorized
        end

        it 'does not update the user' do
          contributor = Contributor.find_by(telegram_id: 789)
          expect(contributor).to have_attributes(first_name: nil, last_name: nil)
        end
      end

      context 'expired signature' do
        before { setup_telegram_id_cookie(contributor) }

        it 'is unauthorized' do
          passed_expiration_time = 31.minutes.from_now
          Timecop.travel(passed_expiration_time) do
            subject.call
            expect(response).to be_unauthorized
          end
        end
      end
    end

    context 'valid' do
      before { setup_telegram_id_cookie(contributor) }

      it 'updates the contributor' do
        subject.call
        contributor = Contributor.find_by(telegram_id: 789)
        expect(contributor).to have_attributes(first_name: 'Update', last_name: 'MyNames')
      end
    end
  end
end

def setup_telegram_id_cookie(contributor)
  my_cookies = ActionDispatch::Request.new(Rails.application.env_config.deep_dup).cookie_jar
  my_cookies.encrypted[:telegram_id] = { value: contributor.telegram_id, expires: 30.minutes }
  cookies[:telegram_id] = my_cookies[:telegram_id]
end

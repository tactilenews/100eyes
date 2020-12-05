# frozen_string_literal: true

require 'rails_helper'
require 'telegram/bot/rspec/integration/rails'

RSpec.describe 'Onboarding', type: :request do
  let(:contributor) { create(:contributor) }
  let(:jwt) { JsonWebToken.encode({ invite_code: 'ONBOARDING_TOKEN', action: 'onboarding' }) }
  let(:params) { { jwt: jwt } }

  describe 'GET /index' do
    subject { -> { get onboarding_path(**params) } }

    it 'should be successful' do
      subject.call
      expect(response).to be_successful
    end

    describe 'with invalidated jwt' do
      let!(:invalidated_jwt) { create(:json_web_token, invalidated_jwt: 'INVALID_JWT') }
      let(:jwt) { 'INVALID_JWT' }

      it 'renders unauthorized page' do
        subject.call

        expect(response).not_to be_successful
      end
    end

    describe 'with jwt unsigned' do
      let(:jwt) { 'UNSIGNED_JWT' }

      it 'renders unauthorized page' do
        subject.call

        expect(response).not_to be_successful
      end
    end
  end

  describe 'GET /onboarding/telegram' do
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

      context 'creates a new update' do
        before { allow(JsonWebToken).to receive(:encode) }

        it 'jwt token' do
          subject.call
          expect(JsonWebToken).to have_received(:encode)
        end
      end

      context 'expired signature' do
        let(:passed_expiration_time) { 31.minutes.from_now }

        it 'throws an error' do
          subject.call

          doc = Nokogiri::HTML(response.body)
          relative_path = doc.css('form').first.attributes['action']
          search_params = CGI.parse(URI.parse(relative_path).query)
          jwt = search_params['jwt'].first

          Timecop.travel(passed_expiration_time) do
            patch onboarding_telegram_update_info_path, params: { jwt: jwt }
            expect(response).to be_unauthorized
          end
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

  describe 'PATCH /telegram-update-info' do
    let!(:contributor) { create(:contributor, telegram_id: 789, first_name: nil, last_name: nil) }
    let(:attrs) do
      {
        first_name: 'Update',
        last_name: 'MyNames'
      }
    end
    let(:params) { { jwt: jwt, contributor: attrs } }
    subject { -> { patch onboarding_telegram_update_info_path, params: params } }

    context 'invalid' do
      context 'no telegram id' do
        let(:jwt) { JsonWebToken.encode({ telegram_id: nil, action: 'update' }) }

        it 'is not successful' do
          subject.call
          expect(response).not_to be_successful
        end

        it 'does not redirect to success' do
          subject.call
          expect(response).not_to redirect_to onboarding_success_path
        end

        it 'does not update the user' do
          subject.call
          contributor = Contributor.where(telegram_id: 789).first
          expect(contributor.first_name).to be_nil
          expect(contributor.last_name).to be_nil
        end
      end

      context 'action not equal to update' do
        let(:jwt) { JsonWebToken.encode({ telegram_id: 789, action: 'onboarding' }) }

        it 'is not successful' do
          subject.call
          expect(response).not_to be_successful
        end

        it 'does not redirect to success' do
          subject.call
          expect(response).not_to redirect_to onboarding_success_path
        end

        it 'does not update the user' do
          subject.call
          contributor = Contributor.where(telegram_id: 789).first
          expect(contributor.first_name).to be_nil
          expect(contributor.last_name).to be_nil
        end
      end

      context 'expired signature' do
        let!(:jwt) { JsonWebToken.encode({ telegram_id: 789, action: 'update' }, expires_in: 30.minutes.from_now.to_i) }

        it 'throws an error' do
          passed_expiration_time = 31.minutes.from_now
          Timecop.travel(passed_expiration_time) do
            subject.call
            expect(response).to be_unauthorized
          end
        end
      end
    end

    context 'valid' do
      let(:jwt) { JsonWebToken.encode({ telegram_id: 789, action: 'update' }) }
      it 'updates the contributor' do
        subject.call
        contributor = Contributor.where(telegram_id: 789).first
        expect(contributor.first_name).to eq('Update')
        expect(contributor.last_name).to eq('MyNames')
      end
    end
  end

  describe 'POST /create' do
    let(:attrs) do
      {
        first_name: 'Zora',
        last_name: 'Zimmermann',
        email: 'zora@example.org'
      }
    end

    let(:params) { { jwt: jwt, contributor: attrs } }

    subject { -> { post onboarding_path, params: params } }

    it 'creates contributor' do
      expect { subject.call }.to change(Contributor, :count).by(1)

      contributor = Contributor.first
      expect(contributor.first_name).to eq('Zora')
      expect(contributor.last_name).to eq('Zimmermann')
      expect(contributor.email).to eq('zora@example.org')
    end

    it 'redirects to success page' do
      subject.call
      expect(response).to redirect_to onboarding_success_path
    end

    it 'invalidates the jwt' do
      expect { subject.call }.to change(JsonWebToken, :count).by(1)

      json_web_token = JsonWebToken.where(invalidated_jwt: jwt)
      expect(json_web_token).to exist
    end

    describe 'given an existing email address' do
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

    describe 'with unsigned jwt' do
      let(:jwt) { 'INCORRECT_TOKEN' }

      it 'renders unauthorized page' do
        subject.call

        expect(response).not_to be_successful
      end

      it 'does not create new contributor' do
        expect { subject.call }.not_to change(Contributor, :count)
      end
    end
  end

  describe 'POST /onboarding/invite' do
    let(:user) { nil }

    subject { -> { post onboarding_invite_path(as: user) } }

    it 'is unsuccessful' do
      subject.call
      expect(response).not_to be_successful
    end

    describe 'as a logged-in user' do
      let(:user) { create(:user) }

      it 'responds with a url with a jwt search query' do
        subject.call
        url = JSON.parse(response.body)['url']
        expect(url).to include('/onboarding?jwt=')
      end
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'
require 'telegram/bot/rspec/integration/rails'

RSpec.describe 'Onboarding', type: :request do
  let(:contributor) { create(:contributor) }
  let(:jwt) { JsonWebToken.encode('ONBOARDING_TOKEN') }
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
    let(:headers) { nil }

    subject { -> { post onboarding_invite_path, headers: headers } }

    it 'is unsuccessful' do
      subject.call
      expect(response).not_to be_successful
    end

    describe 'as a logged-in user' do
      let(:headers) { auth_headers }

      it 'responds with a url with a jwt search query' do
        subject.call
        url = JSON.parse(response.body)['url']
        expect(url).to include('/onboarding?jwt=')
      end
    end
  end
end

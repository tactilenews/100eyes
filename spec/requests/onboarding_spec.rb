# frozen_string_literal: true

require 'rails_helper'
require 'telegram/bot/rspec/integration/rails'

RSpec.describe 'Onboarding', type: :request do
  let(:user) { create(:user) }
  let(:token) { 'ONBOARDING_TOKEN' }
  let(:params) { { token: token } }

  describe 'GET /index' do
    subject { -> { get onboarding_path(**params) } }

    it 'should be successful' do
      subject.call
      expect(response).to be_successful
    end

    describe 'with incorrect token' do
      let(:token) { 'INCORRECT_TOKEN' }

      it 'is not successful' do
        expect { subject.call }.to raise_exception(ActionController::BadRequest)
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

    let(:params) { { token: token, user: attrs } }

    subject { -> { post onboarding_path, params: params } }

    it 'creates user' do
      expect { subject.call }.to change(User, :count).by(1)

      user = User.first
      expect(user.first_name).to eq('Zora')
      expect(user.last_name).to eq('Zimmermann')
      expect(user.email).to eq('zora@example.org')
    end

    it 'redirects to success page' do
      subject.call
      expect(response).to redirect_to onboarding_success_path(token: token)
    end

    describe 'given an existing email address' do
      let!(:user) { create(:user, **attrs) }

      it 'redirects to success page' do
        subject.call
        expect(response).to redirect_to onboarding_success_path(token: token)
      end

      it 'does not create new user' do
        expect { subject.call }.not_to change(User, :count)
      end
    end

    describe 'with incorrect token' do
      let(:token) { 'INCORRECT_TOKEN' }

      it 'is not successful' do
        expect { subject.call }.to raise_exception(ActionController::BadRequest)
      end
    end
  end
end

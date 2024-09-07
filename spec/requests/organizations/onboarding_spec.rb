# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '/:organization_id/onboarding', type: :request do
  let(:organization) { create(:organization) }

  describe 'GET /index' do
    let(:jwt) { JsonWebToken.encode({ invite_code: 'ONBOARDING_TOKEN', action: 'onboarding' }) }
    let(:params) { { jwt: jwt } }
    let(:action) { -> { get organization_onboarding_path(organization, **params) } }

    describe 'HTTP status' do
      subject { action.call && response }
      it { is_expected.to have_http_status(:ok) }

      describe 'with invalidated jwt' do
        let!(:json_web_token) { create(:json_web_token, invalidated_jwt: jwt) }
        it { is_expected.to have_http_status(:unauthorized) }

        describe 'with corresponding contributor who needs to connect to Telegram' do
          subject { action.call }
          let!(:contributor) do
            create(:contributor, telegram_onboarding_token: 'SOMETHING', telegram_id: nil, json_web_token: json_web_token)
          end
          it { is_expected.to redirect_to organization_onboarding_telegram_link_path(organization, telegram_onboarding_token: 'SOMETHING') }
        end
      end

      describe 'with jwt unsigned' do
        let(:jwt) { 'UNSIGNED_JWT' }
        it { is_expected.to have_http_status(:unauthorized) }
      end
    end
  end

  describe 'GET /success' do
    let(:action) { -> { get organization_onboarding_success_path(organization) } }
    describe 'HTTP status' do
      subject { action.call && response }
      it { is_expected.to have_http_status(:ok) }
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Onboarding::Whatsapp' do
  let(:jwt) { JsonWebToken.encode({ invite_code: 'ONBOARDING_TOKEN', action: 'onboarding', organization_id: create(:organization).id }) }

  describe 'GET /onboarding/whats_app' do
    subject { -> { get onboarding_whats_app_path(jwt: jwt) } }

    describe 'when no whats_app_server_phone_number is configured' do
      before { allow(Setting).to receive(:whats_app_server_phone_number).and_return(nil) }

      it 'returns a 404 not found' do
        subject.call

        expect(response).to have_http_status(:not_found)
      end
    end

    describe 'but when whats_app_server_phone_number is configured' do
      it 'returns a 200 ok' do
        subject.call

        expect(response).to have_http_status(:ok)
      end
    end
  end
end

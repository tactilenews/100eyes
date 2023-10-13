# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api' do
  let(:external_id) { 'amzn1.ask.account.valid_uuid' }
  let(:attrs) do
    {
      first_name: 'John',
      external_id: external_id
    }
  end
  let(:secret_key) { Rails.application.secrets.secret_key_base.to_s }
  let(:algorithm) { 'HS256' }
  let(:valid_jwt) { JWT.encode({ data: payload }, secret_key, algorithm) }
  let(:payload) { { api_key: SecureRandom.base64(16), action: 'api' } }
  let(:auth_headers) { {} }

  describe 'GET /contributor' do
    subject { -> { get '/v1/contributor', params: { external_id: external_id }, headers: auth_headers } }

    describe 'not authorized' do
      it 'returns not authorized' do
        subject.call

        expect(response).to have_http_status(:unauthorized)
      end
    end

    describe 'authorized' do
      let(:auth_headers) do
        { 'Authorization' => "Bearer #{valid_jwt}" }
      end
      context 'unknown contributor' do
        it 'returns not found' do
          subject.call
          expect(response).to have_http_status(:not_found)
        end
      end

      context 'known contributor' do
        before { create(:contributor, external_id: external_id) }

        it 'returns first name and external id' do
          subject.call

          expect(response.body).to eq(attrs.to_json)
        end
      end
    end
  end

  describe 'POST /v1/onboard' do
    subject { -> { post v1_onboard_path, params: attrs, headers: auth_headers } }

    describe 'not authorized' do
      it 'returns not authorized' do
        subject.call

        expect(response).to have_http_status(:unauthorized)
      end
    end

    describe 'authorized' do
      let(:auth_headers) do
        { 'Authorization' => "Bearer #{valid_jwt}" }
      end

      context 'unknown contributor' do
        it 'creates a contributor' do
          expect { subject.call }.to change(Contributor, :count).from(0).to(1)
        end

        it 'returns internal id' do
          subject.call

          expect(response.body).to eq({ id: Contributor.first.id }.to_json)
        end
      end

      context 'known contributor' do
        let!(:contributor) { create(:contributor, external_id: external_id) }

        it 'does not change contributor count' do
          expect { subject.call }.not_to change(Contributor, :count)
        end

        it 'returns internal id' do
          subject.call

          expect(response.body).to eq({ id: Contributor.first.id }.to_json)
        end
      end
    end
  end
end

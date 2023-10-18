# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api' do
  let(:external_id) { 'amzn1.ask.account.valid_uuid' }
  let(:token) { invalid_token }
  let(:headers) { {} }
  let(:valid_headers) do
    {
      'Authorization' => "Bearer #{token}",
      'X-100eyes-External-Id' => external_id
    }
  end
  let(:invalid_token) do
    'XyoBRczv5bzH_jZhkatxP-1WYZr996z3tCIVgn4LHbCAUHG8Er3XzXR31dp509T3-Ym9z9neosZnmJwnyIRdrE4h0VNki4r1jKBIhjQTRXV4w08qpLSrDHa8ZnG7czLbRasPJ1'
  end

  describe 'GET /contributors/me' do
    subject { -> { get '/v1/contributors/me', headers: headers } }

    describe 'not authorized' do
      context 'missing auth headers' do
        it 'returns not authorized' do
          subject.call

          expect(response).to have_http_status(:unauthorized)
          expect(response.code.to_i).to eq(401)
        end
      end

      context 'invalid token' do
        let(:headers) { { 'Authorization' => "Bearer #{invalid_token}" } }

        it 'returns not authorized' do
          subject.call

          expect(response.body).to eq('What is happening, why a 500 when the tests pass locally?')
          expect(response).to have_http_status(:unauthorized)
          expect(response.code.to_i).to eq(401)
        end
      end
    end

    describe 'authorized' do
      before { allow(Setting).to receive(:api_token).and_return(token) }
      let(:headers) { valid_headers }

      context 'unknown contributor' do
        it 'returns not found' do
          subject.call

          expect(response).to have_http_status(:not_found)
          expect(response.code.to_i).to eq(404)
        end

        it 'returns error status with message Not found' do
          subject.call

          expect(response.body).to eq({ status: 'error', message: 'Not found' }.to_json)
        end
      end

      context 'known contributor' do
        before { create(:contributor, external_id: external_id) }
        let(:expected_response) do
          {
            status: 'ok',
            data:
             {
               first_name: 'John',
               external_id: external_id
             }
          }.to_json
        end

        it 'returns first name and external id' do
          subject.call

          expect(response.body).to eq(expected_response)
          expect(response.code.to_i).to eq(200)
        end
      end
    end
  end

  describe 'POST /v1/contributors' do
    subject { -> { post v1_contributors_path, params: { first_name: 'John' }, headers: headers } }

    describe 'not authorized' do
      context 'missing auth headers' do
        it 'returns not authorized' do
          subject.call

          expect(response).to have_http_status(:unauthorized)
          expect(response.code.to_i).to eq(401)
        end
      end

      context 'invalid token' do
        let(:headers) { { 'Authorization' => "Bearer #{invalid_token}" } }

        it 'returns not authorized' do
          subject.call

          expect(response.body).to eq('What is happening, why a 500 when the tests pass locally?')
          expect(response).to have_http_status(:unauthorized)
          expect(response.code.to_i).to eq(401)
        end
      end
    end

    describe 'authorized' do
      before { allow(Setting).to receive(:api_token).and_return(token) }

      let(:headers) { valid_headers }
      let(:expected_response) do
        {
          first_name: 'John',
          external_id: external_id
        }
      end

      context 'unknown contributor' do
        it 'creates a contributor' do
          expect { subject.call }.to change(Contributor, :count).from(0).to(1)
        end

        it 'returns internal id' do
          subject.call

          expect(JSON.parse(response.body)).to eq({ status: 'ok',
                                                    data: expected_response.merge(id: Contributor.first.id) }.with_indifferent_access)
          expect(response.code.to_i).to eq(201)
        end
      end

      context 'known contributor' do
        let!(:contributor) { create(:contributor, external_id: external_id) }

        it 'does not change contributor count' do
          expect { subject.call }.not_to change(Contributor, :count)
        end

        it 'returns internal id' do
          subject.call

          expect(JSON.parse(response.body)).to eq({ status: 'ok',
                                                    data: expected_response.merge(id: contributor.id) }.with_indifferent_access)
          expect(response.code.to_i).to eq(201)
        end
      end
    end
  end

  describe 'GET /contributors/me/requests/current' do
    subject { -> { get '/v1/contributors/me/requests/current', headers: headers } }

    describe 'not authorized' do
      context 'missing auth headers' do
        it 'returns not authorized' do
          subject.call

          expect(response).to have_http_status(:unauthorized)
          expect(response.code.to_i).to eq(401)
        end
      end

      context 'invalid token' do
        let(:headers) { { 'Authorization' => "Bearer #{invalid_token}" } }

        it 'returns not authorized' do
          subject.call

          expect(response.body).to eq('What is happening, why a 500 when the tests pass locally?')
          expect(response).to have_http_status(:unauthorized)
          expect(response.code.to_i).to eq(401)
        end
      end
    end

    describe 'authorized' do
      before { allow(Setting).to receive(:api_token).and_return(token) }
      let(:headers) { valid_headers }

      context 'unknown contributor' do
        it 'returns not found' do
          subject.call

          expect(response).to have_http_status(:not_found)
          expect(response.code.to_i).to eq(404)
        end

        it 'returns error status with message Not found' do
          subject.call

          expect(response.body).to eq({ status: 'error', message: 'Not found' }.to_json)
        end
      end

      context 'known contributor' do
        let(:contributor) { create(:contributor, external_id: external_id) }
        let!(:message) { create(:message, :outbound, recipient_id: contributor.id) }
        let(:expected_response) do
          {
            status: 'ok',
            data:
             {
               id: message.request.id,
               personalized_text: message.request.personalized_text(contributor),
               contributor_replies_count: contributor.replies.where(request_id: message.request.id).count
             }
          }.to_json
        end

        it 'returns resource data' do
          subject.call

          expect(response.body).to eq(expected_response)
          expect(response.code.to_i).to eq(200)
        end
      end
    end

    describe 'POST /v1/contributors/me/messages' do
      subject { -> { post v1_contributors_me_messages_path, params: { text: 'Create this message' }, headers: headers } }

      describe 'not authorized' do
        context 'missing auth headers' do
          it 'returns not authorized' do
            subject.call

            expect(response.body).to eq('What is happening, why a 500 when the tests pass locally?')
            expect(response).to have_http_status(:unauthorized)
            expect(response.code.to_i).to eq(401)
          end
        end

        context 'invalid token' do
          let(:headers) { { 'Authorization' => "Bearer #{invalid_token}" } }

          it 'returns not authorized' do
            subject.call

            expect(response).to have_http_status(:unauthorized)
            expect(response.code.to_i).to eq(401)
          end
        end
      end

      describe 'authorized' do
        before { allow(Setting).to receive(:api_token).and_return(token) }

        let(:headers) { valid_headers }
        let(:expected_response) do
          {
            status: 'ok',
            data: {
              id: Message.first.id,
              text: Message.first.text
            }
          }
        end

        context 'unknown contributor' do
          it 'returns not found' do
            subject.call

            expect(response).to have_http_status(:not_found)
            expect(response.code.to_i).to eq(404)
          end
        end

        context 'known contributor' do
          let!(:contributor) { create(:contributor, external_id: external_id) }
          let!(:request) { create(:request) }

          it 'creates a message' do
            expect { subject.call }.to change(Message, :count).by(1)
          end

          it 'returns resource data' do
            subject.call

            expect(response.body).to eq(expected_response.to_json)
            expect(response.code.to_i).to eq(201)
          end
        end
      end
    end
  end
end

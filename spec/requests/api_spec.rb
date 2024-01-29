# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api' do
  let(:external_id) { 'amzn1.ask.account.valid_uuid' }
  let(:external_channel) { 'alexa' }
  let(:token) { SecureRandom.urlsafe_base64(128) }
  let(:headers) { {} }
  let(:valid_headers) do
    {
      'Authorization' => "Bearer #{token}",
      'X-100eyes-External-Id' => external_id
    }
  end
  let(:invalid_token) { SecureRandom.urlsafe_base64(128) }
  before { allow(Setting).to receive(:api_token).and_return(token) }

  describe 'GET /v1/contributors/me' do
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

          expect(response).to have_http_status(:unauthorized)
          expect(response.code.to_i).to eq(401)
        end
      end
    end

    describe 'authorized' do
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
        let!(:contributor) { create(:contributor, first_name: 'John', external_id: external_id) }
        let(:expected_response) do
          {
            status: 'ok',
            data:
             {
               first_name: 'John',
               external_id: external_id,
               active: true
             }
          }
        end

        context 'inactive contributor' do
          before do
            contributor.update(deactivated_at: Time.current)
            expected_response[:data][:active] = false
          end

          it 'returns first name, external id, and active state' do
            subject.call

            expect(response.body).to eq(expected_response.to_json)
            expect(response.code.to_i).to eq(200)
          end
        end

        context 'active contributor' do
          it 'returns first name, external id, and active state' do
            subject.call

            expect(response.body).to eq(expected_response.to_json)
            expect(response.code.to_i).to eq(200)
          end
        end
      end
    end
  end

  describe 'POST /v1/contributors' do
    subject { -> { post v1_contributors_path, params: params, headers: headers } }

    let(:params) { { first_name: 'john', external_channel: external_channel } }

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

          expect(response).to have_http_status(:unauthorized)
          expect(response.code.to_i).to eq(401)
        end
      end
    end

    describe 'authorized' do
      let(:headers) { valid_headers }
      let(:expected_response) do
        {
          first_name: 'John',
          external_id: external_id,
          external_channel: external_channel
        }
      end

      context 'no first name provided' do
        let(:params) { { first_name: '' } }

        let(:expected_response) do
          {
            status: 'error',
            message: 'First name muss ausgefüllt werden'
          }.with_indifferent_access
        end
        it { is_expected.not_to change(Contributor, :count) }

        it 'returns error with message' do
          subject.call

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.code.to_i).to eq(422)
          expect(JSON.parse(response.body)).to eq(expected_response)
        end
      end

      context 'unknown contributor' do
        it 'creates a contributor' do
          expect { subject.call }.to change(Contributor, :count).from(0).to(1)
        end

        it 'returns contributor info, with capitalized first name' do
          subject.call

          expect(JSON.parse(response.body)).to eq({ status: 'ok',
                                                    data: expected_response.merge(id: Contributor.first.id) }.with_indifferent_access)
          expect(response.code.to_i).to eq(201)
        end
      end

      context 'known contributor' do
        let!(:contributor) { create(:contributor, external_id: external_id, external_channel: external_channel) }

        it 'does not change contributor count' do
          expect { subject.call }.not_to change(Contributor, :count)
        end

        it 'returns contributor info, with capitalized first name' do
          subject.call

          expect(JSON.parse(response.body)).to eq({ status: 'ok',
                                                    data: expected_response.merge(id: contributor.id) }.with_indifferent_access)
          expect(response.code.to_i).to eq(201)
        end
      end
    end
  end

  describe 'GET /v1/contributors/me/requests/current' do
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

          expect(response).to have_http_status(:unauthorized)
          expect(response.code.to_i).to eq(401)
        end
      end
    end

    describe 'authorized' do
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

    describe 'PUT /v1/contributors/me' do
      subject { -> { put '/v1/contributors/me', params: params, headers: headers } }

      let(:params) { { phone_number: '+491234567' } }

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

            expect(response).to have_http_status(:unauthorized)
            expect(response.code.to_i).to eq(401)
          end
        end
      end

      describe 'authorized' do
        let(:headers) { valid_headers }
        let(:expected_response) do
          {
            status: 'ok',
            data: {
              id: contributor.id,
              first_name: contributor.first_name,
              external_id: external_id,
              phone_number: '+491234567'
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

          it 'returns resource data' do
            subject.call

            expect(response.body).to eq(expected_response.to_json)
            expect(response.code.to_i).to eq(200)
          end
        end
      end
    end

    describe 'POST /v1/users/me/messages' do
      subject { -> { post v1_users_me_messages_path, params: params, headers: headers } }

      let(:params) do
        {
          text: 'This is my response',
          jwt: jwt
        }
      end
      let(:user) { create(:user) }
      let(:payload) do
        {
          email: user.email,
          encrypted_password: user.encrypted_password
        }
      end

      let(:jwt) do
        JWT.encode(payload, Setting.api_token, 'HS256')
      end

      before { allow(Setting).to receive(:api_token).and_return(SecureRandom.urlsafe_base64) }

      context 'missing jwt token' do
        let(:params) { { text: 'am I a user, or not?' } }

        it 'returns not authorized' do
          subject.call

          expect(response).to have_http_status(:unauthorized)
          expect(response.code.to_i).to eq(401)
        end
      end

      describe 'authorized' do
        context 'unknown user' do
          it 'returns not found' do
            subject.call

            expect(response).to have_http_status(:not_found)
            expect(response.code.to_i).to eq(404)
          end
        end

        context 'unknown contributor' do
          it 'returns not found' do
            subject.call

            expect(response).to have_http_status(:not_found)
            expect(response.code.to_i).to eq(404)
          end
        end

        context 'known contributor' do
          let!(:contributor) { create(:contributor, first_name: 'John', external_id: external_id) }
          let!(:request) { create(:request) }
          let(:headers) { { 'X-100eyes-External-Id' => external_id } }
          let(:created_message) { Message.first }
          let(:expected_response) do
            {
              status: 'ok',
              data: {
                id: created_message.id,
                text: created_message.text
              }
            }
          end

          it 'creates the message' do
            expect { subject.call }.to change(Message, :count).by(1)
          end

          it 'assigns correct attrs' do
            subject.call

            expect(created_message).to have_attributes(
              request: request,
              sender: user,
              text: params[:text],
              broadcasted: false,
              recipient: contributor
            )
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

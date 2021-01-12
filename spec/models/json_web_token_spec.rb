# frozen_string_literal: true

require 'rails_helper'

RSpec.describe JsonWebToken, type: :model do
  let(:secret_key) { Rails.application.secrets.secret_key_base.to_s }
  let(:algorithm) { 'HS256' }
  let!(:valid_jwt) { JWT.encode({ data: payload, exp: 48.hours.from_now.to_i }, secret_key, 'HS256') }
  let(:payload) { { invite_code: SecureRandom.base64(16), action: 'onboarding' } }

  describe '.encode(payload)' do
    let(:jwt_mock) { double('Ruby JWT', encode: valid_jwt) }

    context 'Default' do
      it 'creates a jwt that expires in 48 hours' do
        expect(JWT).to receive(:encode).with({ data: payload, exp: 48.hours.from_now.to_i }, secret_key, algorithm).and_return(:jwt_mock)

        described_class.encode(payload)
      end
    end

    context 'With passed in expiration' do
      let(:expires_in) { 30.minutes.from_now.to_i }
      it 'respects expiration' do
        expect(JWT).to receive(:encode).with({ data: payload, exp: expires_in }, secret_key, algorithm).and_return(:jwt_mock)

        described_class.encode(payload, expires_in: expires_in)
      end
    end
  end

  describe '.decode(token)' do
    let(:jwt_mock) { double('JWT token') }
    let(:decoded_token) do
      [{
        'data' =>
        {
          'invite_code' => 'NrzYTJqq+MI+e2Gen6lDVg==',
          'action' => 'onboarding'
        },
        'exp' => 48.hours.from_now.to_i
      },
       { 'alg' => 'HS256' }]
    end

    context 'Valid token' do
      it 'decodes the token' do
        expect(JWT).to receive(:decode).with(valid_jwt, secret_key, true, { algorithm: algorithm }).and_return(decoded_token)

        described_class.decode(valid_jwt)
      end
    end

    context 'Invalid token' do
      it 'expired' do
        passed_expiration_time = 48.hours.from_now + 1.minute

        Timecop.travel(passed_expiration_time) do
          expect { described_class.decode(valid_jwt) }.to raise_error(JWT::ExpiredSignature)
        end
      end

      context 'unsigned token' do
        let(:unsigned_token) { JWT.encode({ data: payload, exp: 48.hours.from_now.to_i }, 'some other signature', 'HS256') }

        it 'invalid token' do
          expect { described_class.decode(unsigned_token) }.to raise_error(JWT::DecodeError)
        end
      end
    end
  end
end

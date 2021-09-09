# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Onboarding::Signal', type: :request do
  let(:signal_phone_number) { '+4915112345678' }
  let(:data_processing_consent) { true }
  let(:jwt) { JsonWebToken.encode({ invite_code: 'ONBOARDING_TOKEN', action: 'onboarding' }) }
  let(:params) { { jwt: jwt } }

  describe 'POST /onboarding/signal' do
    let(:attrs) do
      {
        first_name: 'Zora',
        last_name: 'Zimmermann',
        signal_phone_number: signal_phone_number,
        data_processing_consent: data_processing_consent
      }
    end

    let(:params) { { jwt: jwt, contributor: attrs, context: :contributor_signup } }

    subject { -> { post onboarding_signal_path, params: params } }

    it 'creates contributor' do
      expect { subject.call }.to change(Contributor, :count).by(1)

      contributor = Contributor.first
      expect(contributor).to have_attributes(
        first_name: 'Zora',
        last_name: 'Zimmermann',
        signal_phone_number: '+4915112345678',
        data_processing_consent: true
      )
      expect(contributor.json_web_token).to have_attributes(
        invalidated_jwt: jwt
      )
    end

    it 'does not send welcome message' do
      should_not enqueue_job(SignalAdapter::Outbound).with(text: anything, recipient: anything)
    end

    it 'redirects to onboarding signal link page' do
      subject.call
      expect(response).to redirect_to onboarding_signal_link_path
    end

    it 'invalidates the jwt' do
      expect { subject.call }.to change(JsonWebToken, :count).by(1)

      json_web_token = JsonWebToken.where(invalidated_jwt: jwt)
      expect(json_web_token).to exist
    end

    context 'given invalid phone number' do
      let(:signal_phone_number) { 'invalid-phone-number' }

      it 'displays validation errors' do
        subject.call
        parsed = Capybara::Node::Simple.new(response.body)
        fields = parsed.all('.Field')
        signal_phone_number_field = fields.find { |f| f.has_text? 'Signal Telefonnummer' }
        expect(signal_phone_number_field).to have_text('ist keine gültige Nummer')
      end

      it 'has 422 status code' do
        subject.call
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'without data processing consent' do
      let(:data_processing_consent) { false }

      it 'displays validation errors' do
        subject.call
        parsed = Capybara::Node::Simple.new(response.body)
        fields = parsed.all('.Field')
        data_processing_consent_field = fields.find { |f| f.has_text? 'Datenschutzerklärung' }
        expect(data_processing_consent_field).to have_text('muss akzeptiert werden')
      end

      it 'does not create new contributor' do
        expect { subject.call }.not_to change(Contributor, :count)
      end

      it 'has 422 status code' do
        subject.call
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    describe 'if a contributor exists with the same phone number' do
      let!(:contributor) { create(:contributor, **attrs.merge(json_web_token: create(:json_web_token, invalidated_jwt: :jwt))) }

      it 'redirects to success page so that an attacker cannot make a phone number listing' do
        subject.call
        expect(response).to redirect_to onboarding_signal_link_path
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

        expect(response).to have_http_status(:unauthorized)
      end

      it 'does not create new contributor' do
        expect { subject.call }.not_to change(Contributor, :count)
      end
    end

    describe 'with invalidated jwt' do
      let!(:invalidated_jwt) { create(:json_web_token, invalidated_jwt: 'INVALID_JWT') }
      let(:jwt) { 'INVALID_JWT' }

      it 'renders unauthorized page' do
        subject.call

        expect(response).to have_http_status(:unauthorized)
      end

      it 'does not create new contributor' do
        expect { subject.call }.not_to change(Contributor, :count)
      end
    end
  end
end

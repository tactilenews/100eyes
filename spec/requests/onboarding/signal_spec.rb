# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Onboarding::Signal', type: :request do
  let(:signal_phone_number) { '+4915112345678' }
  let(:data_processing_consent) { true }
  let(:additional_consent) { true }
  let(:jwt) { JsonWebToken.encode({ invite_code: 'ONBOARDING_TOKEN', action: 'onboarding' }) }
  let(:params) { { jwt: jwt } }

  describe 'GET /onboarding/signal' do
    subject { -> { get onboarding_signal_path(jwt: jwt) } }

    before(:each) { allow(Setting).to receive(:signal_server_phone_number).and_return(signal_server_phone_number) }

    context 'if Signal is not set up on the server' do
      let(:signal_server_phone_number) { nil }

      it 'show 404 error page' do
        subject.call
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'if Signal is set up on the server' do
      let(:signal_server_phone_number) { '+4915258595146' }

      it 'is successful' do
        subject.call
        expect(response).to be_successful
      end
    end
  end

  describe 'POST /onboarding/signal' do
    let(:attrs) do
      {
        first_name: 'Zora',
        last_name: 'Zimmermann',
        signal_phone_number: signal_phone_number,
        data_processing_consent: data_processing_consent,
        additional_consent: additional_consent
      }
    end

    let(:params) { { jwt: jwt, contributor: attrs, context: :contributor_signup } }

    subject { -> { post onboarding_signal_path, params: params } }

    before(:each) { allow(Setting).to receive(:signal_server_phone_number).and_return('+4491234567890') }

    it 'creates contributor' do
      expect { subject.call }.to change(Contributor, :count).by(1)

      contributor = Contributor.first
      expect(contributor).to have_attributes(
        first_name: 'Zora',
        last_name: 'Zimmermann',
        signal_phone_number: '+4915112345678',
        data_processing_consent: data_processing_consent,
        additional_consent: additional_consent
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
      expect(response).to redirect_to onboarding_signal_link_path(jwt: nil)
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
        signal_phone_number_field = fields.find { |f| f.has_text? 'Handynummer' }
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
        expect(response).to redirect_to onboarding_signal_link_path(jwt: nil)
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

    context 'without additional consent' do
      let(:additional_consent) { false }

      it 'creates contributor without additional consent' do
        expect { subject.call }.to change(Contributor, :count).by(1)

        contributor = Contributor.first
        expect(contributor).to have_attributes(
          first_name: 'Zora',
          last_name: 'Zimmermann',
          signal_phone_number: '+4915112345678',
          data_processing_consent: data_processing_consent,
          additional_consent: additional_consent
        )
      end
    end

    describe 'invalid jwt' do
      let(:onboarding_unauthorized_heading_record) { Setting.new(var: :onboarding_unauthorized_heading) }
      let(:onboarding_unauthorized_text_record) { Setting.new(var: :onboarding_unauthorized_text) }

      before do
        allow(Setting).to receive(:find_by).with(var: :onboarding_unauthorized_heading).and_return(onboarding_unauthorized_heading_record)
        allow(onboarding_unauthorized_heading_record).to receive(:send).with("value_#{I18n.locale}".to_sym).and_return('Unauthorized')
        allow(Setting).to receive(:find_by).with(var: :onboarding_unauthorized_text).and_return(onboarding_unauthorized_text_record)
        allow(onboarding_unauthorized_text_record).to receive(:send).with("value_#{I18n.locale}".to_sym).and_return('Sorry')
      end

      context 'with unsigned jwt' do
        let(:jwt) { 'INCORRECT_TOKEN' }

        it 'renders unauthorized page' do
          subject.call

          expect(response).to have_http_status(:unauthorized)
        end

        it 'does not create new contributor' do
          expect { subject.call }.not_to change(Contributor, :count)
        end
      end

      context 'with invalidated jwt' do
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
end

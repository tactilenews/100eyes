# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Onboarding::Signal', type: :request do
  let(:signal_server_phone_number) { nil }
  let(:data_processing_consent) { true }
  let(:additional_consent) { true }
  let!(:organization) do
    create(:organization, signal_server_phone_number: signal_server_phone_number, onboarding_allowed: onboarding_allowed, users_count: 1)
  end
  let!(:admin) { create_list(:user, 2, admin: true) }
  let(:onboarding_allowed) { { signal: true } }
  let(:jwt) { JsonWebToken.encode({ invite_code: 'ONBOARDING_TOKEN', action: 'onboarding' }) }
  let(:params) { { jwt: jwt } }

  describe 'GET /{organization_id}/onboarding/signal' do
    subject { -> { get organization_onboarding_signal_path(organization, jwt: jwt) } }

    describe 'when no signal server phone number is configured' do
      it 'returns a 404 not found' do
        subject.call

        expect(response).to have_http_status(:not_found)
      end
    end

    describe 'when a signal server phone number is configured, but onboarding has been disallowed by an admin' do
      let(:signal_server_phone_number) { '+4915112345678' }
      let(:onboarding_allowed) { { signal: false } }

      it 'returns a 404 not found' do
        subject.call

        expect(response).to have_http_status(:not_found)
      end
    end

    describe 'but when a signal server phone number is configured and onboarding has not been disallowed' do
      let(:signal_server_phone_number) { '+4915112345678' }

      it 'returns a 200 ok' do
        subject.call

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'POST /{organization_id}/onboarding/signal' do
    let(:attrs) do
      {
        first_name: 'Zora',
        last_name: 'Zimmermann',
        signal_onboarding_token: signal_onboarding_token,
        data_processing_consent: data_processing_consent,
        additional_consent: additional_consent
      }
    end

    let(:params) { { jwt: jwt, contributor: attrs, context: :contributor_signup } }
    let(:signal_onboarding_token) { SecureRandom.alphanumeric(8).upcase }

    subject { -> { post organization_onboarding_signal_path(organization), params: params } }

    describe 'when no signal server phone number is configured' do
      it 'returns a 404 not found' do
        subject.call

        expect(response).to have_http_status(:not_found)
      end
    end

    describe 'when a signal server phone number is configured, but onboarding has been disallowed by an admin' do
      let(:signal_server_phone_number) { '+4915112345678' }
      let(:onboarding_allowed) { { signal: false } }

      it 'returns a 404 not found' do
        subject.call

        expect(response).to have_http_status(:not_found)
      end
    end

    describe 'but when a signal server phone number is configured and onboarding has not been disallowed' do
      let(:signal_server_phone_number) { '+4915112345678' }

      it 'creates contributor' do
        expect { subject.call }.to change(Contributor, :count).by(1)

        contributor = Contributor.first
        expect(contributor).to have_attributes(
          first_name: 'Zora',
          last_name: 'Zimmermann',
          signal_onboarding_token: signal_onboarding_token,
          data_processing_consent: data_processing_consent,
          additional_consent: additional_consent
        )
        expect(contributor.json_web_token).to have_attributes(
          invalidated_jwt: jwt
        )
      end

      it 'redirects to success page' do
        subject.call
        expect(response).to redirect_to organization_onboarding_signal_link_path(organization,
                                                                                 jwt: nil,
                                                                                 signal_onboarding_token: signal_onboarding_token)
      end

      it 'invalidates the jwt' do
        expect { subject.call }.to change(JsonWebToken, :count).by(1)

        json_web_token = JsonWebToken.where(invalidated_jwt: jwt)
        expect(json_web_token).to exist
      end

      context 'creates an ActivityNotification' do
        it_behaves_like 'an ActivityNotification', 'OnboardingCompleted', 3
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

      context 'without additional consent' do
        let(:additional_consent) { false }

        it 'creates contributor without additional consent' do
          expect { subject.call }.to change(Contributor, :count).by(1)

          contributor = Contributor.first
          expect(contributor).to have_attributes(
            first_name: 'Zora',
            last_name: 'Zimmermann',
            data_processing_consent: data_processing_consent,
            additional_consent: additional_consent
          )
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
end

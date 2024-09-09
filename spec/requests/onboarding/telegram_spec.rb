# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Onboarding::Telegram', type: :request do
  let!(:organization) do
    create(:organization, telegram_bot_api_key: telegram_bot_api_key, onboarding_allowed: onboarding_allowed, users_count: 1)
  end
  let!(:admin) { create_list(:user, 2, admin: true) }
  let(:telegram_bot_api_key) { nil }
  let(:onboarding_allowed) { { telegram: true } }

  describe 'GET /{organization_id}/onboarding/telegram' do
    let(:jwt) { JsonWebToken.encode({ invite_code: 'ONBOARDING_TOKEN', action: 'onboarding' }) }
    let(:params) { { jwt: jwt } }
    subject { -> { get organization_onboarding_telegram_path(organization), params: params } }
    before do
      allow(SecureRandom).to receive(:alphanumeric).with(8).and_return('TELEGRAM_ONBOARDING_TOKEN')
    end

    describe 'when no telegram bot is configured' do
      it 'returns a 404 not found' do
        subject.call

        expect(response).to have_http_status(:not_found)
      end
    end

    describe 'when a telegram bot is configured, but onboarding has been disallowed by an admin' do
      let(:telegram_bot_api_key) { 'valid_api_key' }
      let(:onboarding_allowed) { { telegram: false } }

      it 'returns a 404 not found' do
        subject.call

        expect(response).to have_http_status(:not_found)
      end
    end

    describe 'but when a telegram bot is configured and onboarding has not been disallowed' do
      let(:telegram_bot_api_key) { 'valid_api_key' }

      it 'returns a 200 ok' do
        subject.call

        expect(response).to have_http_status(:ok)
      end

      it 'renders hidden <input value="TELEGRAM_ONBOARDING_TOKEN">' do
        subject.call
        parsed = Capybara::Node::Simple.new(response.body)
        expect(parsed).to have_css('input[value="TELEGRAM_ONBOARDING_TOKEN"]', visible: :hidden)
      end

      describe 'with unsigned jwt' do
        let(:jwt) { 'INCORRECT_TOKEN' }
        describe 'http status' do
          subject { super().call && response }
          it { is_expected.to have_http_status(:unauthorized) }
        end
      end
    end
  end

  describe 'POST /{organization_id}/onboarding/telegram' do
    let(:jwt) { JsonWebToken.encode({ invite_code: 'ONBOARDING_TOKEN', action: 'onboarding' }) }
    let(:params) { { jwt: jwt } }
    let(:data_processing_consent) { true }
    let(:additional_consent) { true }

    let(:attrs) do
      {
        first_name: 'Zora',
        last_name: 'Zimmermann',
        data_processing_consent: data_processing_consent,
        telegram_onboarding_token: 'TELEGRAM_ONBOARDING_TOKEN',
        additional_consent: additional_consent
      }
    end

    let(:params) { { jwt: jwt, contributor: attrs, context: :contributor_signup } }

    subject { -> { post organization_onboarding_telegram_path(organization), params: params } }

    describe 'when no telegram bot is configured' do
      it 'returns a 404 not found' do
        subject.call

        expect(response).to have_http_status(:not_found)
      end
    end

    describe 'when a telegram bot is configured, but onboarding has been disallowed by an admin' do
      let(:telegram_bot_api_key) { 'valid_api_key' }
      let(:onboarding_allowed) { { telegram: false } }

      it 'returns a 404 not found' do
        subject.call

        expect(response).to have_http_status(:not_found)
      end
    end

    describe 'but when a telegram bot is configured and onboarding has not been disallowed' do
      let(:telegram_bot_api_key) { 'valid_api_key' }

      it 'creates contributor' do
        expect { subject.call }.to change(Contributor, :count).by(1)

        contributor = Contributor.first
        expect(contributor).to have_attributes(
          first_name: 'Zora',
          last_name: 'Zimmermann',
          data_processing_consent: data_processing_consent,
          telegram_onboarding_token: 'TELEGRAM_ONBOARDING_TOKEN',
          additional_consent: additional_consent
        )
        expect(contributor.json_web_token).to have_attributes(
          invalidated_jwt: jwt
        )
      end

      it { should_not enqueue_job(TelegramAdapter::Outbound) }

      it 'redirects to telegram link page' do
        subject.call
        expect(response).to redirect_to organization_onboarding_telegram_link_path(organization,
                                                                                   telegram_onboarding_token: 'TELEGRAM_ONBOARDING_TOKEN')
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
            telegram_onboarding_token: 'TELEGRAM_ONBOARDING_TOKEN',
            additional_consent: additional_consent
          )
        end
      end

      describe 'with unsigned jwt' do
        let(:jwt) { 'INCORRECT_TOKEN' }

        it 'renders unauthorized page' do
          subject.call

          expect(response).not_to be_successful
        end

        it 'does not create new contributor' do
          expect { subject.call }.not_to change(Contributor, :count)
        end
      end

      describe 'with invalidated jwt' do
        let!(:invalidated_jwt) { create(:json_web_token, invalidated_jwt: 'INVALID_JWT') }
        let(:jwt) { 'INVALID_JWT' }

        describe 'http status' do
          subject { super().call && response }
          it { is_expected.to have_http_status(:unauthorized) }
        end

        it 'does not create new contributor' do
          expect { subject.call }.not_to change(Contributor, :count)
        end
      end
    end
  end

  describe 'GET /{onboarding_id}/onboarding/telegram/link' do
    subject { -> { get organization_onboarding_telegram_link_path(organization, telegram_onboarding_token: 'TELEGRAM_ONBOARDING_TOKEN') } }

    describe 'when no telegram bot is configured' do
      it 'returns a 404 not found' do
        subject.call

        expect(response).to have_http_status(:not_found)
      end
    end

    describe 'when a telegram bot is configured, but onboarding has been disallowed by an admin' do
      let(:telegram_bot_api_key) { 'valid_api_key' }
      let(:onboarding_allowed) { { telegram: false } }

      it 'returns a 404 not found' do
        subject.call

        expect(response).to have_http_status(:not_found)
      end
    end

    describe 'but when a telegram bot is configured and onboarding has not been disallowed' do
      let(:telegram_bot_api_key) { 'valid_api_key' }

      it 'is successful without JWT' do
        subject.call
        expect(response).to be_successful
      end
    end
  end

  describe 'GET /{organization_id}/onboarding/telegram/fallback' do
    let(:jwt) { JsonWebToken.encode({ invite_code: 'ONBOARDING_TOKEN', action: 'onboarding' }) }
    let(:json_web_token) { create(:json_web_token, invalidated_jwt: jwt) }
    let!(:contributor) do
      create(:contributor, telegram_onboarding_token: 'TELEGRAM_ONBOARDING_TOKEN', telegram_id: nil, json_web_token: json_web_token,
                           organization: organization)
    end
    let(:action) do
      lambda {
        get organization_onboarding_telegram_fallback_path(organization, telegram_onboarding_token: 'TELEGRAM_ONBOARDING_TOKEN')
      }
    end
    subject { action.call && response }

    describe 'when no telegram bot is configured' do
      it 'returns a 404 not found' do
        expect(subject).to have_http_status(:not_found)
      end
    end

    describe 'when a telegram bot is configured, but onboarding has been disallowed by an admin' do
      let(:telegram_bot_api_key) { 'valid_api_key' }
      let(:onboarding_allowed) { { telegram: false } }

      it 'returns a 404 not found' do
        expect(subject).to have_http_status(:not_found)
      end
    end

    describe 'but when a telegram bot is configured and onboarding has not been disallowed' do
      let(:telegram_bot_api_key) { 'valid_api_key' }

      describe 'redirects' do
        it 'are skipped' do
          is_expected.to have_http_status(:ok)
        end

        describe '(sanity check: / redirects to /link)' do
          let(:action) { -> { get organization_onboarding_telegram_path(organization, jwt: jwt) } }
          it { is_expected.to have_http_status(302) }
        end
      end
    end
  end
end

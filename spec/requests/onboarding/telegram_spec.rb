# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Onboarding::Telegram', type: :request do
  describe 'GET /onboarding/telegram' do
    let(:jwt) { JsonWebToken.encode({ invite_code: 'ONBOARDING_TOKEN', action: 'onboarding' }) }
    let(:params) { { jwt: jwt } }
    subject { -> { get onboarding_telegram_path, params: params } }
    before { allow(SecureRandom).to receive(:alphanumeric).with(8).and_return('TELEGRAM_ONBOARDING_TOKEN') }

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

  describe 'POST /onboarding/telegram' do
    let(:jwt) { JsonWebToken.encode({ invite_code: 'ONBOARDING_TOKEN', action: 'onboarding' }) }
    let(:params) { { jwt: jwt } }
    let(:data_processing_consent) { true }

    let(:attrs) do
      {
        first_name: 'Zora',
        last_name: 'Zimmermann',
        data_processing_consent: data_processing_consent,
        telegram_onboarding_token: 'TELEGRAM_ONBOARDING_TOKEN'
      }
    end

    let(:params) { { jwt: jwt, contributor: attrs, context: :contributor_signup } }

    subject { -> { post onboarding_telegram_path, params: params } }

    it 'creates contributor' do
      expect { subject.call }.to change(Contributor, :count).by(1)

      contributor = Contributor.first
      expect(contributor).to have_attributes(
        first_name: 'Zora',
        last_name: 'Zimmermann',
        data_processing_consent: data_processing_consent,
        telegram_onboarding_token: 'TELEGRAM_ONBOARDING_TOKEN'
      )
      expect(contributor.json_web_token).to have_attributes(
        invalidated_jwt: jwt
      )
    end

    it { should_not enqueue_job(TelegramAdapter::Outbound) }

    it 'redirects to telegram link page' do
      subject.call
      expect(response).to redirect_to onboarding_telegram_link_path(jwt: jwt, telegram_onboarding_token: 'TELEGRAM_ONBOARDING_TOKEN')
    end

    it 'invalidates the jwt' do
      expect { subject.call }.to change(JsonWebToken, :count).by(1)

      json_web_token = JsonWebToken.where(invalidated_jwt: jwt)
      expect(json_web_token).to exist
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

  describe 'GET /onboarding/telegram/link' do
    let(:jwt) { JsonWebToken.encode({ invite_code: 'ONBOARDING_TOKEN', action: 'onboarding' }) }
    let(:params) { { telegram_onboarding_token: 'TELEGRAM_ONBOARDING_TOKEN', jwt: jwt } }
    subject { -> { get onboarding_telegram_link_path(params) } }

    describe 'http status' do
      subject { super().call && response }
      it { is_expected.to have_http_status(:unauthorized) }

      context 'given an invalidated JsonWebToken' do
        let(:json_web_token) { create(:json_web_token, invalidated_jwt: jwt) }
        before { json_web_token }
        it { is_expected.to have_http_status(:unauthorized) }

        context 'with a corresponding contributor' do
          before { contributor }
          describe 'who is not yet connected via Telegram' do
            let(:contributor) do
              create(:contributor, telegram_onboarding_token: 'TELEGRAM_ONBOARDING_TOKEN', telegram_id: nil, json_web_token: json_web_token)
            end
            it { is_expected.to have_http_status(:ok) }

            describe 'but the jwt query parameter is invalid' do
              let(:jwt) { 'INCORRECT_TOKEN' }
              it { is_expected.to have_http_status(:unauthorized) }
            end
          end

          describe 'who is already connected via Telegram' do
            let(:contributor) { create(:contributor, telegram_onboarding_token: 'TELEGRAM_ONBOARDING_TOKEN', telegram_id: 4711) }
            it { is_expected.to have_http_status(:unauthorized) }
          end
        end
      end
    end
  end

  describe 'GET /onboarding/telegram/fallback' do
    let(:jwt) { JsonWebToken.encode({ invite_code: 'ONBOARDING_TOKEN', action: 'onboarding' }) }
    let(:params) { { telegram_onboarding_token: 'TELEGRAM_ONBOARDING_TOKEN', jwt: jwt } }
    let(:json_web_token) { create(:json_web_token, invalidated_jwt: jwt) }
    let(:contributor) do
      create(:contributor, telegram_onboarding_token: 'TELEGRAM_ONBOARDING_TOKEN', telegram_id: nil, json_web_token: json_web_token)
    end
    before { contributor }
    let(:action) { -> { get onboarding_telegram_fallback_path(params) } }
    subject { action.call && response }

    describe 'redirects' do
      it 'are skipped' do
        is_expected.to have_http_status(:ok)
      end

      describe '(sanity check: / redirects to /link)' do
        let(:action) { -> { get onboarding_telegram_path(params) } }
        it { is_expected.to have_http_status(302) }
      end
    end
  end
end

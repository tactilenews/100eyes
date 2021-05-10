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
        telegram_onboarding_token: 'TELEGRAM_ONBOARDING_TOKEN',
        jwt: jwt
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
        telegram_onboarding_token: 'TELEGRAM_ONBOARDING_TOKEN',
        jwt: jwt
      )
    end

    it 'redirects to telegram link page' do
      subject.call
      expect(response).to redirect_to onboarding_telegram_link_path(jwt: nil, telegram_onboarding_token: 'TELEGRAM_ONBOARDING_TOKEN')
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
    let(:params) { { telegram_onboarding_token: 'TELEGRAM_ONBOARDING_TOKEN', jwt: nil } }
    subject { -> { get onboarding_telegram_link_path(params) } }
    before { contributor }
    let(:contributor) { create(:contributor, telegram_onboarding_token: 'TELEGRAM_ONBOARDING_TOKEN', telegram_id: nil) }

    describe 'http status' do
      subject { super().call && response }
      it { is_expected.to have_http_status(:ok) }
    end

    describe 'contributor already connected via Telegram' do
      let(:contributor) { create(:contributor, telegram_onboarding_token: 'TELEGRAM_ONBOARDING_TOKEN', telegram_id: 4711) }

      it 'renders 404' do
        is_expected.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end

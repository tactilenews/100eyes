# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Onboarding', type: :request do
  describe 'GET /onboarding/index' do
    let(:jwt) { JsonWebToken.encode({ invite_code: 'ONBOARDING_TOKEN', action: 'onboarding' }) }
    let(:params) { { jwt: jwt } }
    let(:action) { -> { get onboarding_path(**params) } }

    describe 'HTTP status' do
      let(:onboarding_title_record) { Setting.new(var: :onboarding_title) }
      let(:onboarding_page_record) { Setting.new(var: :onboarding_page) }
      let(:onboarding_imprint_link_record) { Setting.new(var: :onboarding_imprint_link) }
      let(:onboarding_data_protection_link_record) { Setting.new(var: :onboarding_data_protection_link) }

      before do
        allow(Setting).to receive(:find_by).with(var: :onboarding_title).and_return(onboarding_title_record)
        allow(onboarding_title_record).to receive(:send).with("value_#{I18n.locale}".to_sym).and_return('This is 100eyes')
        allow(Setting).to receive(:find_by).with(var: :onboarding_page).and_return(onboarding_page_record)
        allow(onboarding_page_record).to receive(:send).with("value_#{I18n.locale}".to_sym).and_return('We are cool!')
        allow(Setting).to receive(:find_by).with(var: :onboarding_imprint_link).and_return(onboarding_imprint_link_record)
        allow(onboarding_imprint_link_record).to receive(:send).with("value_#{I18n.locale}".to_sym).and_return('https://example.org/imprint')
        allow(Setting).to receive(:find_by).with(var: :onboarding_data_protection_link).and_return(onboarding_data_protection_link_record)
        allow(onboarding_data_protection_link_record).to receive(:send).with("value_#{I18n.locale}".to_sym).and_return('https://example.org/privacy')
      end

      subject { action.call && response }
      it { is_expected.to have_http_status(:ok) }

      describe 'invalid jwt' do
        let(:onboarding_unauthorized_heading_record) { Setting.new(var: :onboarding_unauthorized_heading) }
        let(:onboarding_unauthorized_text_record) { Setting.new(var: :onboarding_unauthorized_text) }

        before do
          allow(Setting).to receive(:find_by).with(var: :onboarding_unauthorized_heading).and_return(onboarding_unauthorized_heading_record)
          allow(onboarding_unauthorized_heading_record).to receive(:send).with("value_#{I18n.locale}".to_sym).and_return('Unauthorized')
          allow(Setting).to receive(:find_by).with(var: :onboarding_unauthorized_text).and_return(onboarding_unauthorized_text_record)
          allow(onboarding_unauthorized_text_record).to receive(:send).with("value_#{I18n.locale}".to_sym).and_return('Sorry')
        end

        context 'with invalidated jwt' do
          let!(:json_web_token) { create(:json_web_token, invalidated_jwt: jwt) }
          it { is_expected.to have_http_status(:unauthorized) }

          describe 'with corresponding contributor who needs to connect to Telegram' do
            subject { action.call }
            let!(:contributor) do
              create(:contributor, telegram_onboarding_token: 'SOMETHING', telegram_id: nil, json_web_token: json_web_token)
            end
            it { is_expected.to redirect_to onboarding_telegram_link_path(telegram_onboarding_token: 'SOMETHING') }
          end
        end

        context 'with jwt unsigned' do
          let(:jwt) { 'UNSIGNED_JWT' }
          it { is_expected.to have_http_status(:unauthorized) }
        end
      end
    end
  end

  describe 'GET /onboarding/success' do
    let(:action) { -> { get onboarding_success_path(**params) } }
    let(:params) { {} }
    let(:onboarding_success_heading_record) { Setting.new(var: :onboarding_success_heading) }
    let(:onboarding_success_text_record) { Setting.new(var: :onboarding_success_text) }

    before do
      allow(Setting).to receive(:find_by).with(var: :onboarding_success_heading).and_return(onboarding_success_heading_record)
      allow(onboarding_success_heading_record).to receive(:send).with("value_#{I18n.locale}".to_sym).and_return('Welcome new contributor!')
      allow(Setting).to receive(:find_by).with(var: :onboarding_success_text).and_return(onboarding_success_text_record)
      allow(onboarding_success_text_record).to receive(:send).with("value_#{I18n.locale}".to_sym).and_return('You onboarded successfully.')
    end
    describe 'HTTP status' do
      subject { action.call && response }
      it { is_expected.to have_http_status(:ok) }
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContributorTelegramSettings::ContributorTelegramSettings, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { { contributor: contributor } }

  let(:contributor) do
    create(:contributor,
           first_name: 'Max',
           last_name: 'Mustermann',
           telegram_id: telegram_id,
           telegram_onboarding_token: onboarding_token,
           username: 'max.mustermann',
           created_at: '2021-01-01')
  end

  let(:telegram_id) { 123 }
  let(:onboarding_token) { nil }

  it { is_expected.to have_css('h2', text: 'Telegram') }
  it { is_expected.to have_css('p', text: 'Max Mustermann hat sich unter dem Telegram-Nutzernamen „max.mustermann” angemeldet.') }

  context 'given a contributor with incomplete onboarding' do
    let(:telegram_id) { nil }
    let(:onboarding_token) { 'ABCD1234' }

    it {
      expect(subject).to have_css('p',
                                  text: 'Max Mustermann hat sich am 01.01.2021 via Telegram angemeldet, die Anmeldung aber noch nicht abgeschlossen.')
    }

    it { is_expected.to have_css('p', text: 'Sende Max einen Link mit Hinweisen zum Abschließen der Anmeldung.') }
    it { is_expected.to have_css('button[data-copy-button-copy-value$="http://test.host/onboarding/telegram/link/ABCD1234"]') }
  end
end

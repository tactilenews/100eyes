# frozen_string_literal: true

require 'rails_helper'

RSpec.describe About::About, type: :component do
  subject { render_inline(described_class.new(**params)) }
  let(:organization) { create(:organization) }
  let(:params) { { organization: organization } }

  it { should have_css('.About') }

  describe 'with every channel set up' do
    let(:organization) do
      create(:organization,
             email_from_address: 'redaktion@example.org',
             telegram_bot_username: 'RedaktionBot',
             telegram_bot_api_key: 'valid_t_key',
             threemarb_api_identity: '*ABCDEFG',
             signal_server_phone_number: '+4915712345678',
             whats_app_server_phone_number: '+4915712345679',
             three_sixty_dialog_client_api_key: 'valid_ts_key')
    end

    describe 'but no onboarding allowed' do
      before do
        organization.update(onboarding_allowed: { 'email' => false, 'signal' => false, 'threema' => false, 'telegram' => false,
                                                  'whats_app' => false })
      end
      it { should have_text('redaktion@example.org: (Inaktiv)') }
      it { should have_text('RedaktionBot: (Inaktiv)') }
      it { should have_text('*ABCDEFG: (Inaktiv)') }
      it { should have_text('0157 1234 5678: (Inaktiv)') }
      it { should have_text('0157 1234 5679: (Inaktiv)') }
    end

    describe 'and all onboarding allowed' do
      it { should have_text('redaktion@example.org: (Aktiv)') }
      it { should have_text('RedaktionBot: (Aktiv)') }
      it { should have_text('*ABCDEFG: (Aktiv)') }
      it { should have_text('0157 1234 5678: (Aktiv)') }
      it { should have_text('0157 1234 5679: (Aktiv)') }
    end
  end

  describe 'With no channel set up' do
    let(:organization) do
      create(:organization,
             email_from_address: nil,
             telegram_bot_username: nil,
             threemarb_api_identity: nil,
             signal_server_phone_number: nil,
             whats_app_server_phone_number: nil)
    end

    it { should have_text('E-Mail Adresse N/A: (Inaktiv)') }
    it { should have_text('Telegram-Handle N/A: (Inaktiv)') }
    it { should have_text('Threema-ID N/A: (Inaktiv)') }
    it { should have_text('Signal Handynummer N/A: (Inaktiv)') }
    it { should have_text('Whats-App Handynummer N/A: (Inaktiv)') }
  end

  context 'with git commit info set' do
    before(:each) do
      allow(ENV).to receive(:fetch).with('GIT_COMMIT_SHA', nil).and_return('abcdef123456')
      allow(ENV).to receive(:fetch).with('GIT_COMMIT_DATE', nil).and_return('2022-01-01T12:34:56+00:00')
      allow(ENV).to receive(:fetch).with('ATTR_ENCRYPTED_KEY', nil).and_return(SecureRandom.bytes(32).unpack1('*H'))
      allow(ENV).to receive(:fetch).with('POSTMARK_API_TOKEN', nil).and_return('valid_token')
    end

    it { should have_text('Version abcdef12 (01.01.2022)') }
  end
end

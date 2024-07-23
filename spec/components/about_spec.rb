# frozen_string_literal: true

require 'rails_helper'

RSpec.describe About::About, type: :component do
  subject { render_inline(described_class.new(**params)) }
  let(:organization) do
    create(:organization,
           email_from_address: 'redaktion@example.org',
           telegram_bot_username: 'RedaktionBot',
           threemarb_api_identity: '*ABCDEFG',
           signal_server_phone_number: nil)
  end
  let(:params) { { organization: organization } }

  it { should have_css('.About') }

  it { should have_text('redaktion@example.org') }
  it { should have_text('RedaktionBot') }
  it { should have_text('*ABCDEFG') }

  describe 'Signal server phone number' do
    context 'without Signal set up' do
      it { should have_text('Signal ist für diese Instanz nicht aktiviert.') }
    end

    context 'with Signal set up' do
      before { organization.update!(signal_server_phone_number: signal_server_phone_number) }

      let(:signal_server_phone_number) { '+4915712345678' }
      it { should have_text('0157 1234 5678') }
    end
  end

  context 'with git commit info set' do
    before(:each) do
      allow(ENV).to receive(:fetch).with('GIT_COMMIT_SHA', nil).and_return('abcdef123456')
      allow(ENV).to receive(:fetch).with('GIT_COMMIT_DATE', nil).and_return('2022-01-01T12:34:56+00:00')
      allow(ENV).to receive(:fetch).with('ATTR_ENCRYPTED_KEY', nil).and_return(SecureRandom.bytes(32).unpack1('*H'))
    end

    it { should have_text('Version abcdef12 (01.01.2022)') }
  end
end

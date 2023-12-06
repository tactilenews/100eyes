# frozen_string_literal: true

require 'rails_helper'

RSpec.describe About::About, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { {} }

  before do
    allow(Setting).to receive(:email_from_address).and_return('redaktion@example.org')
    allow(Setting).to receive(:telegram_bot_username).and_return('RedaktionBot')
    allow(Setting).to receive(:threemarb_api_identity).and_return('*ABCDEFG')
  end

  it { is_expected.to have_css('.About') }

  it { is_expected.to have_text('redaktion@example.org') }
  it { is_expected.to have_text('RedaktionBot') }
  it { is_expected.to have_text('*ABCDEFG') }

  describe 'Signal server phone number' do
    before { allow(Setting).to receive(:signal_server_phone_number).and_return(signal_server_phone_number) }

    context 'without Signal set up' do
      let(:signal_server_phone_number) { nil }

      it { is_expected.to have_text('Signal ist für diese Instanz nicht aktiviert.') }
    end

    context 'with Signal set up' do
      let(:signal_server_phone_number) { '+4915712345678' }

      it { is_expected.to have_text('0157 1234 5678') }
    end
  end

  context 'with git commit info set' do
    before do
      allow(Setting).to receive(:git_commit_sha).and_return('abcdef123456')
      allow(Setting).to receive(:git_commit_date).and_return('2022-01-01T12:34:56+00:00')
    end

    it { is_expected.to have_text('Version abcdef12 (01.01.2022)') }
  end
end

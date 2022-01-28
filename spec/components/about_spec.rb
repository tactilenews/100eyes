# frozen_string_literal: true

require 'rails_helper'

RSpec.describe About::About, type: :component do
  subject { render_inline(described_class.new(**params)) }
  let(:params) { {} }

  before(:each) do
    allow(Setting).to receive(:email_from_address).and_return('redaktion@example.org')
    allow(Setting).to receive(:telegram_bot_username).and_return('RedaktionBot')
    allow(Setting).to receive(:threemarb_api_identity).and_return('*ABCDEFG')
  end

  it { should have_css('.About') }

  it { should have_text('redaktion@example.org') }
  it { should have_text('RedaktionBot') }
  it { should have_text('*ABCDEFG') }
  it { should have_text('Signal ist für diese Instanz nicht aktiviert.') }

  context 'with Signal set up' do
    before(:each) { allow(Setting).to receive(:signal_server_phone_number).and_return('+4915712345678') }

    it { should have_text('0157 1234 5678') }
  end

  context 'with git commit info set' do
    before(:each) do
      allow(Setting).to receive(:git_commit_sha).and_return('abcdef123456')
      allow(Setting).to receive(:git_commit_date).and_return('2022-01-01T12:34:56+00:00')
    end

    it { should have_text('Version abcdef12 (01.01.2022)') }
  end
end

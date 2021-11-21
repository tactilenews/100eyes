# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Onboarding::Telegram::Link::Component, type: :component do
  subject { render_inline(described_class.new(**params)) }
  before do
    allow(Setting).to receive(:telegram_bot_username).and_return('TestingBot')
  end

  let(:params) { { telegram_onboarding_token: 'TELEGRAM_ONBOARDING_TOKEN' } }
  it { should have_css('a[href="https://t.me/TestingBot?start=TELEGRAM_ONBOARDING_TOKEN"]') }

  context 'missing `telegram_onboarding_token`' do
    subject { -> { render_inline(described_class.new) } }
    it { should raise_error(ArgumentError) }
  end
end

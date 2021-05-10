# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OnboardingTelegramLink::OnboardingTelegramLink, type: :component do
  subject { render_inline(described_class.new(**params)) }
  let(:params) { { telegram_onboarding_token: 'TELEGRAM_ONBOARDING_TOKEN' } }
  it { should have_css('a[href="tg://resolve?domain=TestingBot&start=TELEGRAM_ONBOARDING_TOKEN"]') }

  context 'missing `telegram_onboarding_token`' do
    subject { -> { render_inline(described_class.new) } }
    it { should raise_error(ArgumentError) }
  end
end

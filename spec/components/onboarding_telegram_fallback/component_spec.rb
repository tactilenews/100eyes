# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OnboardingTelegramFallback::Component, type: :component do
  subject { render_inline(described_class.new(**params)) }
  before do
    allow(Setting).to receive(:telegram_bot_username).and_return('TestingBot')
  end
  let(:params) { { telegram_onboarding_token: 'TELEGRAM_ONBOARDING_TOKEN' } }

  it { should have_css('strong', text: 'TestingBot') }
  it { should have_css('strong', text: 'TELEGRAM_ONBOARDING_TOKEN') }
end

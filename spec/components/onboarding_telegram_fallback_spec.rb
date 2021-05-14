# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OnboardingTelegramFallback::OnboardingTelegramFallback, type: :component do
  subject { render_inline(described_class.new(**params)) }
  let(:params) { { telegram_onboarding_token: 'TELEGRAM_ONBOARDING_TOKEN' } }

  it { should have_css('strong', text: 'TestingBot') }
  it { should have_css('strong', text: 'TELEGRAM_ONBOARDING_TOKEN') }
end

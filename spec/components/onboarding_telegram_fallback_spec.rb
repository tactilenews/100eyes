# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OnboardingTelegramFallback::OnboardingTelegramFallback, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:organization) do
    create(:organization, name: '100eyes', telegram_bot_api_key: 'TELEGRAM_BOT_API_KEY', telegram_bot_username: 'TestingBot')
  end
  let(:params) { { organization: organization, telegram_onboarding_token: 'TELEGRAM_ONBOARDING_TOKEN' } }

  it { should have_css('strong', text: 'TestingBot') }
  it { should have_css('strong', text: 'TELEGRAM_ONBOARDING_TOKEN') }
end

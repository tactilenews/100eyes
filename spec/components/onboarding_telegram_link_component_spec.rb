# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OnboardingTelegramLink::OnboardingTelegramLink, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:organization) { create(:organization, telegram_bot_username: 'TestingBot') }
  let(:params) { { organization: organization, telegram_onboarding_token: 'TELEGRAM_ONBOARDING_TOKEN' } }
  it { should have_css('a[href="https://t.me/TestingBot?start=TELEGRAM_ONBOARDING_TOKEN"]') }
  it { should have_css('p', text: organization.project_name) }

  context 'missing `telegram_onboarding_token`' do
    subject { -> { render_inline(described_class.new) } }
    it { expect { subject.call }.to raise_error(ArgumentError) }
  end
end

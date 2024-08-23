# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OnboardingChannelButtons::OnboardingChannelButtons, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:organization) { create(:organization) }
  let(:params) { { organization: organization, channels: %w[threema telegram email] } }

  it { should have_css('.Button').exactly(3).times }
  it { should_not have_css('.OnboardingChannelButtons--twoColumn') }

  context 'if Signal is set up' do
    let(:params) { { organization: organization, channels: %w[threema telegram email signal] } }

    it { should have_css('.Button').exactly(4).times }
    it { should have_css('.OnboardingChannelButtons--twoColumn') }
  end

  context 'if WhatsApp is set up' do
    let(:params) { { organization: organization, channels: %w[threema telegram email signal whats_app] } }

    it { should have_css('.Button').exactly(5).times }
    it { should_not have_css('.OnboardingChannelButtons--twoColumn') }
  end
end

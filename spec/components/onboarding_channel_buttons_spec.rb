# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OnboardingChannelButtons::OnboardingChannelButtons, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { { channels: %w[threema telegram email] } }

  it { is_expected.to have_css('.Button').exactly(3).times }
  it { is_expected.not_to have_css('.OnboardingChannelButtons--twoColumn') }

  context 'if Signal is set up' do
    let(:params) { { channels: %w[threema telegram email signal] } }

    it { is_expected.to have_css('.Button').exactly(4).times }
    it { is_expected.to have_css('.OnboardingChannelButtons--twoColumn') }
  end

  context 'if WhatsApp is set up' do
    let(:params) { { channels: %w[threema telegram email signal whats_app] } }

    it { is_expected.to have_css('.Button').exactly(5).times }
    it { is_expected.not_to have_css('.OnboardingChannelButtons--twoColumn') }
  end
end

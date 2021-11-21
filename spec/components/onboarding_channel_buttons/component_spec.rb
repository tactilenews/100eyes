# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OnboardingChannelButtons::Component, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { {} }
  let(:phone_number) { nil }

  before(:each) { allow(Setting).to receive(:signal_server_phone_number).and_return(phone_number) }

  it { should_not have_css('.OnboardingChannelButtons--even') }
  it { should have_css('.Button').exactly(3).times }

  context 'if Signal is set up' do
    let(:phone_number) { '+491234567890' }

    it { should have_css('.Button').exactly(4).times }
    it { should have_css('.OnboardingChannelButtons--even') }
  end
end

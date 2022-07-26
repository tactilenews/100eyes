# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OnboardingSignalLink::OnboardingSignalLink, type: :component do
  subject { render_inline(described_class.new(**params)) }
  let(:params) { {} }
  before(:each) { allow(Setting).to receive(:signal_server_phone_number).and_return('+4915112345678') }

  it { should have_css('.OnboardingSignalLink') }
  it { should have_css('strong', text: '015112345678'.phony_formatted(normalize: :DE, spaces: ' ')) }
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Onboarding::Signal::Link::Component, type: :component do
  subject { render_inline(described_class.new(**params)) }
  let(:params) { {} }
  before(:each) { allow(Setting).to receive(:signal_server_phone_number).and_return('+4915112345678') }

  it { should have_css('.Onboarding-Signal-Link') }

  # \u00a0 is a non-breaking space
  it { should have_css('strong', text: "0151\u00a01234\u00a05678") }
end

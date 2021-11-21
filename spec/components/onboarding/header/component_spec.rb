# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Onboarding::Header::Component, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { { logo: '/onboarding/logo.png' } }
  it { should have_css('.Onboarding-Header') }
end

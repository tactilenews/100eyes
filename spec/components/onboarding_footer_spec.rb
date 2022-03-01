# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OnboardingFooter::OnboardingFooter, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { {} }

  before(:each) do
    allow(Setting).to receive(:onboarding_imprint_link).and_return('https://example.org/imprint')
    allow(Setting).to receive(:onboarding_data_protection_link).and_return('https://example.org/privacy')
  end

  it { should have_css('.OnboardingFooter') }
  it { should have_css('a[href="https://example.org/imprint"]', text: 'Impressum') }
  it { should have_css('a[href="https://example.org/privacy"]', text: 'Datenschutz') }
end

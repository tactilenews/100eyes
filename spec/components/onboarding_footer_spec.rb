# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OnboardingFooter::OnboardingFooter, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { {} }

  before do
    allow(Setting).to receive(:onboarding_imprint_link).and_return('https://example.org/imprint')
    allow(Setting).to receive(:onboarding_data_protection_link).and_return('https://example.org/privacy')
  end

  it { is_expected.to have_css('.OnboardingFooter') }
  it { is_expected.to have_css('a[href="https://example.org/imprint"]', text: 'Impressum') }
  it { is_expected.to have_css('a[href="https://example.org/privacy"]', text: 'Datenschutz') }
end

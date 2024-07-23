# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OnboardingFooter::OnboardingFooter, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:organization) do
    create(:organization, onboarding_imprint_link: 'https://example.org/imprint',
                          onboarding_data_protection_link: 'https://example.org/privacy')
  end

  let(:params) { { organization: organization } }

  it { should have_css('.OnboardingFooter') }
  it { should have_css('a[href="https://example.org/imprint"]', text: 'Impressum') }
  it { should have_css('a[href="https://example.org/privacy"]', text: 'Datenschutz') }
end

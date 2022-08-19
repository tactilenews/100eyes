# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OnboardingFooter::OnboardingFooter, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { {} }
  let(:onboarding_imprint_link_record) { Setting.new(var: :onboarding_imprint_link) }
  let(:onboarding_data_protection_link_record) { Setting.new(var: :onboarding_data_protection_link) }

  before(:each) do
    allow(Setting).to receive(:find_by).with(var: :onboarding_imprint_link).and_return(onboarding_imprint_link_record)
    allow(onboarding_imprint_link_record).to receive(:send).with("value_#{I18n.locale}".to_sym).and_return('https://example.org/imprint')
    allow(Setting).to receive(:find_by).with(var: :onboarding_data_protection_link).and_return(onboarding_data_protection_link_record)
    allow(onboarding_data_protection_link_record).to receive(:send).with("value_#{I18n.locale}".to_sym).and_return('https://example.org/privacy')
  end

  it { should have_css('.OnboardingFooter') }
  it { should have_css('a[href="https://example.org/imprint"]', text: 'Impressum') }
  it { should have_css('a[href="https://example.org/privacy"]', text: 'Datenschutz') }
end

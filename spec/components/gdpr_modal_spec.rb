# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GdprModal::GdprModal, type: :component do
  subject { render_inline(described_class.new(**params)) }
  let(:params) { {} }
  let(:onboarding_data_protection_link_record) { Setting.new(var: :onboarding_data_protection_link) }

  before do
    allow(Setting).to receive(:find_by).with(var: :onboarding_data_protection_link).and_return(onboarding_data_protection_link_record)
    allow(onboarding_data_protection_link_record).to receive(:send).with("value_#{I18n.locale}".to_sym).and_return('https://example.org/privacy')
  end

  it { should have_css('.GdprModal') }
  it { should have_css('h2', text: 'Datenschutz') }
  it { should have_link('Datenschutzerklärung', href: 'https://example.org/privacy') }
end

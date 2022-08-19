# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OnboardingConsent::OnboardingConsent, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:contributor) { build(:contributor) }
  let(:params) { { contributor: contributor } }
  let(:onboarding_additional_consent_heading_record) { Setting.new(var: :onboarding_additional_consent_heading) }
  let(:onboarding_additional_consent_text_record) { Setting.new(var: :onboarding_additional_consent_text) }

  before do
    allow(Setting).to receive(:onboarding_ask_for_additional_consent).and_return(true)
    allow(Setting).to receive(:find_by)
      .with(var: :onboarding_additional_consent_heading).and_return(onboarding_additional_consent_heading_record)
    allow(onboarding_additional_consent_heading_record).to receive(:send)
      .with("value_#{I18n.locale}".to_sym).and_return('Great expectations.')
    allow(Setting).to receive(:find_by)
      .with(var: :onboarding_additional_consent_text).and_return(onboarding_additional_consent_text_record)
    allow(onboarding_additional_consent_text_record).to receive(:send).with("value_#{I18n.locale}".to_sym)
  end

  describe 'data processing consent checkbox' do
    it {
      should have_field('Einwilligung zur Datenverarbeitung', type: :checkbox, id: 'contributor[data_processing_consent]', checked: false)
    }
    it { should have_link(href: Setting.onboarding_data_protection_link) }
  end

  describe 'additional consent checkbox' do
    context 'if additional consent checkbox is enabled' do
      it { should have_field('Great expectations.', type: :checkbox, id: 'contributor[additional_consent]', checked: false) }
    end

    context 'if additional consent checkbox is disabled' do
      before { allow(Setting).to receive(:onboarding_ask_for_additional_consent).and_return(false) }
      it { should_not have_field(:checkbox, id: 'contributor[additional_consent]') }
    end

    context 'if consent heading is empty' do
      before { allow(onboarding_additional_consent_heading_record).to receive(:send).with("value_#{I18n.locale}".to_sym).and_return(' ') }
      it { should_not have_field(:checkbox, id: 'contributor[additional_consent]') }
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OnboardingConsent::OnboardingConsent, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:contributor) { build(:contributor) }
  let(:params) { { contributor: contributor } }

  describe 'data processing consent checkbox' do
    it {
      expect(subject).to have_field('Einwilligung zur Datenverarbeitung', type: :checkbox, id: 'contributor[data_processing_consent]',
                                                                          checked: false)
    }

    it { is_expected.to have_link(href: Setting.onboarding_data_protection_link) }
  end

  describe 'additional consent checkbox' do
    before do
      allow(Setting).to receive(:onboarding_ask_for_additional_consent).and_return(true)
      allow(Setting).to receive(:onboarding_additional_consent_heading).and_return('Great expectations.')
    end

    context 'if additional consent checkbox is enabled' do
      it { is_expected.to have_text(Setting.onboarding_additional_consent_heading) }
      it { is_expected.to have_field('Great expectations.', type: :checkbox, id: 'contributor[additional_consent]', checked: false) }
    end

    context 'if additional consent checkbox is disabled' do
      before { allow(Setting).to receive(:onboarding_ask_for_additional_consent).and_return(false) }

      it { is_expected.not_to have_field(:checkbox, id: 'contributor[additional_consent]') }
    end

    context 'if consent heading is empty' do
      before { allow(Setting).to receive(:onboarding_additional_consent_heading).and_return('  ') }

      it { is_expected.not_to have_field(:checkbox, id: 'contributor[additional_consent]') }
    end
  end
end

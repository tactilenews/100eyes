# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OnboardingConsent::OnboardingConsent, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:contributor) { build(:contributor) }
  let(:organization) { build(:organization) }
  let(:params) { { organization: organization, contributor: contributor } }

  describe 'data processing consent checkbox' do
    it {
      should have_field('Einwilligung zur Datenverarbeitung', type: :checkbox, id: 'contributor[data_processing_consent]', checked: false)
    }
    it { should have_link(href: organization.onboarding_data_protection_link) }
  end

  describe 'additional consent checkbox' do
    context 'if additional consent checkbox is enabled' do
      before do
        organization.onboarding_ask_for_additional_consent = true
        organization.onboarding_additional_consent_heading = 'Great expectations.'
      end
      it { should have_text('Great expectations.') }
      it { should have_field('Great expectations.', type: :checkbox, id: 'contributor[additional_consent]', checked: false) }
    end

    context 'if additional consent checkbox is disabled' do
      before do
        organization.onboarding_ask_for_additional_consent = false
      end
      it { should_not have_field(:checkbox, id: 'contributor[additional_consent]') }
    end

    context 'if consent heading is empty' do
      before { organization.onboarding_additional_consent_heading = '  ' }
      it { should_not have_field(:checkbox, id: 'contributor[additional_consent]') }
    end
  end
end

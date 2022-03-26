# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OnboardingEmailForm::OnboardingEmailForm, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:contributor) { build(:contributor) }
  let(:params) { { contributor: contributor, jwt: 'JWT' } }

  it { should have_css('.OnboardingEmailForm') }
  it { should have_link(href: Setting.onboarding_data_protection_link) }

  describe 'additional consent check box' do
    before do
      Setting.ask_for_additional_consent = true
      Setting.additional_consent_heading = 'Great expectations.'
    end
    context 'given a request for additional consent' do
      it { should have_text(Setting.additional_consent_heading) }
      it { should have_css('input[type="checkbox"][name="contributor[additional_consent]"]') }
    end

    context 'given no request for additional consent' do
      before do
        Setting.ask_for_additional_consent = false
      end
      it { should_not have_css('input[type="checkbox"][name="contributor[additional_consent]"]') }
    end

    context 'given no specified additional consent heading' do
      before do
        Setting.additional_consent_heading = '  '
      end
      it { should_not have_css('input[type="checkbox"][name="contributor[additional_consent]"]') }
    end
  end
end

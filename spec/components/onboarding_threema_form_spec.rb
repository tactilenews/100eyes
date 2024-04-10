# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OnboardingThreemaForm::OnboardingThreemaForm, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:contributor) { build(:contributor) }
  let(:params) { { contributor: contributor } }

  it { is_expected.to have_css('.OnboardingThreemaForm') }
end

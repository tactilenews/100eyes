# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OnboardingInstructions::OnboardingInstructions, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:contributor) { build(:contributor) }
  let(:params) { { contributor: contributor, jwt: 'JWT' } }

  it { should have_css('.OnboardingInstructions') }
end

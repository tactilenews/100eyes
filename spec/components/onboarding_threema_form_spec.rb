# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OnboardingThreemaForm::OnboardingThreemaForm, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:organization) { create(:organization) }
  let(:contributor) { build(:contributor) }
  let(:params) { { organization: organization, contributor: contributor } }

  it { should have_css('.OnboardingThreemaForm') }
end

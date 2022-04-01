# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OnboardingTelegramForm::OnboardingTelegramForm, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:contributor) { build(:contributor) }
  let(:params) { { contributor: contributor } }

  it { should have_css('.OnboardingTelegramForm') }
end

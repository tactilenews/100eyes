# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OnboardingEmailForm::OnboardingEmailForm, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:user) { build(:user) }
  let(:params) { { user: user } }

  it { should have_css('.OnboardingEmailForm') }
end

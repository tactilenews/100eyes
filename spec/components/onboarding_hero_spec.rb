# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OnboardingHero::OnboardingHero, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { { image: '/onboarding/photo.jpg' } }
  it { should have_css('.OnboardingHero') }
end

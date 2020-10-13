# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OnboardingSuccess::OnboardingSuccess, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { { heading: 'Hello', text: 'World' } }
  it { should have_css('.OnboardingSuccess') }
end

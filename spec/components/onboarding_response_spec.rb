# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OnboardingResponse::OnboardingResponse, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { { heading: 'Hello', text: 'World' } }

  it { is_expected.to have_css('.OnboardingResponse') }
end

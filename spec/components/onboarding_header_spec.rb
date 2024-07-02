# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OnboardingHeader::OnboardingHeader, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:organization) { create(:organization, project_name: 'Der Community-Dialog!') }
  let(:params) { { organization: organization } }

  it { should have_css('.OnboardingHeader', text: 'Der Community-Dialog!') }
end

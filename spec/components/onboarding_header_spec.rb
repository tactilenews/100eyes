# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OnboardingHeader::OnboardingHeader, type: :component do
  subject { render_inline(described_class.new) }
  before(:each) { allow(Setting).to receive(:project_name).and_return('Der Community-Dialog!') }
  it { should have_css('.OnboardingHeader', text: 'Der Community-Dialog!') }
end

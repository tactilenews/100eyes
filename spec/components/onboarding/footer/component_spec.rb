# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Onboarding::Footer::Component, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { { imprint_link: '#' } }
  it { should have_css('.Onboarding-Footer') }
end

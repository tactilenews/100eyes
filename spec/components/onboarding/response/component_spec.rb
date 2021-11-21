# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Onboarding::Response::Component, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { { heading: 'Hello', text: 'World' } }
  it { should have_css('.Onboarding-Response') }
end

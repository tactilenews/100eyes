# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Onboarding::Hero::Component, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { { image: '/onboarding/photo.jpg' } }
  it { should have_css('.Onboarding-Hero') }
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LoadingIndicator::LoadingIndicator, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { {} }
  it { should have_css('.LoadingIndicator') }
end

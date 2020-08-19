# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Metric::Metric, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { {} }
  it { should have_css('.Metric') }
end

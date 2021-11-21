# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InlineMetrics::Component, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { { metrics: [] } }

  it { should have_css('.InlineMetrics') }
end

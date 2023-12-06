# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InlineMetrics::InlineMetrics, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { { metrics: [] } }

  it { is_expected.to have_css('.InlineMetrics') }
end

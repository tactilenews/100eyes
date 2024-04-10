# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Metrics::Metrics, type: :component do
  subject { render_inline(described_class.new(**params)) }

  describe 'with inline style' do
    let(:params) { { metrics: [], style: :inline } }

    it { is_expected.to have_css('.InlineMetrics') }
  end

  describe 'with cards style' do
    let(:params) { { metrics: [], style: :cards } }

    it { is_expected.to have_css('.CardMetrics') }
  end
end

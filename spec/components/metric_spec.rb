# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Metric::Metric, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { { style: style, value: value, total: total, label: label, icon: icon } }
  let(:style) { :inline }
  let(:value) { 50 }
  let(:total) { nil }
  let(:label) { '# of comments' }
  let(:icon) { 'comment' }

  it { is_expected.to have_css('.Metric') }
  it { is_expected.to have_text('# of comments') }

  describe 'without total value' do
    it { is_expected.to have_text('50') }
    it { is_expected.not_to have_css('.Metric-progress') }
  end

  describe 'with total value' do
    let(:total) { 100 }

    it { is_expected.to have_text('50/100') }

    describe 'with inline style' do
      it { is_expected.not_to have_css('.Metric-progress') }
    end

    describe 'with large style' do
      let(:style) { :large }

      it { is_expected.to have_css('.Metric-progress[style="--progress: calc(50 / 100 * 100%)"]') }
    end
  end
end

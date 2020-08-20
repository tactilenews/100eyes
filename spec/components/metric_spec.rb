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

  it { should have_css('.Metric') }
  it { should have_text('# of comments') }

  describe 'without total value' do
    it { should have_text('50') }
    it { should_not have_css('.Metric-progress') }
  end

  describe 'with total value' do
    let(:total) { 100 }

    it { should have_text('50/100') }

    describe 'with inline style' do
      it { should_not have_css('.Metric-progress') }
    end

    describe 'with large style' do
      let(:style) { :large }
      it { should have_css('.Metric-progress[style="--progress: calc(50 / 100 * 100%)"]') }
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Button::Button, type: :component do
  subject { render_inline(described_class.new(**params)) }

  describe 'given a block' do
    subject { render_inline(described_class.new()) { 'Slot content' } }
    it { should have_text('Slot content') }
    it { should have_css('button.Button') }
  end

  describe 'given label param' do
    let(:params) { { label: 'Button label' } }
    it { should have_text('Button label') }
  end

  describe 'given an optional type' do
    let(:params) { { type: 'submit' } }
    it { should have_css('button[type="submit"]') }
  end

  describe 'given a link' do
    let(:params) { { link: '#' } }
    it { should have_css('a[href="#"]') }
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Textarea::Textarea, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { {} }
  it { should have_css('textarea.Textarea') }

  describe 'given an id' do
    let(:params) { { id: 'message' } }
    it { should have_css('textarea[id="message"]') }
  end

  describe 'given a value' do
    let(:params) { { value: 'Lorem Ipsum dolor sit amet.' } }
    it { should have_text('Lorem Ipsum dolor sit amet.') }
  end

  describe 'when required' do
    let(:params) { { required: true } }
    it { should have_css('textarea[required]') }
  end

  describe 'given a placeholder' do
    let(:params) { { placeholder: 'Enter your message here!' } }
    it { should have_css('textarea[placeholder="Enter your message here!"]') }
  end
end

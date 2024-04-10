# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Input::Input, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { {} }

  it { is_expected.to have_css('.Input input') }

  describe 'given an id' do
    let(:params) { { id: 'name' } }

    it { is_expected.to have_css('input[id="name"]') }
  end

  describe 'given a value' do
    let(:params) { { value: 'Lutra lutra' } }

    it { is_expected.to have_css('input[value="Lutra lutra"]') }
  end

  describe 'when required' do
    let(:params) { { required: true } }

    it { is_expected.to have_css('input[required]') }
  end

  describe 'given a placeholder' do
    let(:params) { { placeholder: 'Enter your name here!' } }

    it { is_expected.to have_css('input[placeholder="Enter your name here!"]') }
  end
end

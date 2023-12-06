# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationComponent, type: :component do
  let(:params) { {} }

  let(:test_component) do
    Class.new(ApplicationComponent) do
      def initialize(some_property: '', **)
        super
      end
    end
  end

  before { Object.const_set('TestComponent', test_component) }

  after { Object.send(:remove_const, 'TestComponent') }

  describe '#class_names' do
    subject { TestComponent.new(**params).send(:class_names) }

    it { is_expected.to eq(['TestComponent']) }

    describe 'given a list of styles' do
      let(:params) { { styles: %i[style_a style_b] } }

      it { is_expected.to eq(['TestComponent', 'TestComponent--styleA', 'TestComponent--styleB']) }
    end
  end

  describe '#attrs' do
    subject { TestComponent.new(**params).send(:attrs).to_hash }

    it { is_expected.to eq({ class: 'TestComponent' }) }

    context 'with attributes given explicitly' do
      let(:params) { { id: 'my-component' } }

      it { is_expected.to eq({ class: 'TestComponent', id: 'my-component' }) }
    end

    context 'with style, styles properties' do
      let(:params) { { styles: [:style_a], style: :style_b } }

      it { is_expected.to eq({ class: 'TestComponent TestComponent--styleA TestComponent--styleB' }) }
    end
  end
end

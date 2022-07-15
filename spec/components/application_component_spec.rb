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

  before(:each) { Object.const_set('TestComponent', test_component) }
  after(:each) { Object.send(:remove_const, 'TestComponent') }

  describe '#class_names' do
    subject { TestComponent.new(**params).send(:class_names) }

    it { should eq(['TestComponent']) }

    describe 'given a list of styles' do
      let(:params) { { styles: %i[style_a style_b] } }
      it { should eq(['TestComponent', 'TestComponent--styleA', 'TestComponent--styleB']) }
    end
  end

  describe '#attrs' do
    subject { TestComponent.new(**params).send(:attrs).to_hash }
    it { should eq({ class: 'TestComponent' }) }

    context 'with attributes given explicitly' do
      let(:params) { { id: 'my-component' } }
      it { should eq({ class: 'TestComponent', id: 'my-component' }) }
    end

    context 'with style, styles properties' do
      let(:params) { { styles: [:style_a], style: :style_b } }
      it { should eq({ class: 'TestComponent TestComponent--styleA TestComponent--styleB' }) }
    end
  end
end

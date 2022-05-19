# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationComponent, type: :component do
  let(:params) { {} }

  before(:all) do
    button_class = Class.new(ApplicationComponent) do
      def initialize(label: '', **)
        super

        @label = label
      end

      def call
        button.tag(label, **attrs)
      end
    end

    Object.const_set('Button', button_class)
  end

  describe '#class_names' do
    subject { Button.new(**params).send(:class_names) }

    it { should eq(['Button']) }

    describe 'given a list of styles' do
      let(:params) { { styles: %i[large primary] } }
      it { should eq(['Button', 'Button--large', 'Button--primary']) }
    end
  end

  describe '#attrs' do
    subject { Button.new(**params).send(:attrs).to_hash }
    it { should eq({ class: 'Button' }) }

    context 'with attributes given explicitly' do
      let(:params) { { id: 'my-component' } }
      it { should eq({ class: 'Button', id: 'my-component' }) }
    end

    context 'with style, styles properties' do
      let(:params) { { style: :large, styles: [:primary] } }
      it { should eq({ class: 'Button Button--primary Button--large' }) }
    end
  end
end

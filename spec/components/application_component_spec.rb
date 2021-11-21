# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationComponent, type: :component do
  let(:params) { {} }
  before { stub_const('HelloWorld::Component', Class.new(ApplicationComponent)) }

  describe '#class_names' do
    subject { HelloWorld::Component.new(**params).send(:class_names) }

    it { should eq(['HelloWorld']) }

    describe 'given a list of styles' do
      let(:params) { { styles: %w[large brandColor] } }
      it { should eq(['HelloWorld', 'HelloWorld--large', 'HelloWorld--brandColor']) }
    end
  end

  describe '#attrs' do
    subject { HelloWorld::Component.new(**params).send(:attrs).attrs }
    it { should eq({ class: 'HelloWorld' }) }

    context 'with attributes given explicitly' do
      let(:params) { { id: 'my-component' } }
      it { should eq({ class: 'HelloWorld', id: 'my-component' }) }
    end
  end
end

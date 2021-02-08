# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationComponent, type: :component do
  describe '#class_names' do
    subject { described_class.new(**params).send(:class_names) }

    let(:params) { {} }
    it { should eq(['ApplicationComponent']) }

    describe 'given a list of styles' do
      let(:params) { { styles: %w[large brandColor] } }
      it { should eq(['ApplicationComponent', 'ApplicationComponent--large', 'ApplicationComponent--brandColor']) }
    end
  end

  describe '#data_string' do
    subject { described_class.new(**params).send(:data_string) }

    let(:params) { {} }
    it { should eq('') }

    describe 'given data attributes as a hash' do
      let(:params) do
        {
          data: {
            controller: 'my-controller',
            target: 'my-target',
            action: 'click->my-controller#myAction'
          }
        }
      end

      let(:expected) do
        [
          'data-controller="my-controller"',
          'data-target="my-target"',
          'data-action="click->my-controller#myAction"'
        ]
      end

      it { should eq(expected.join(' ')) }
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationComponent, type: :component do
  let(:params) { {} }

  describe '#class_names' do
    subject { described_class.new(**params).send(:class_names) }

    it { should eq(['ApplicationComponent']) }

    describe 'given a list of styles' do
      let(:params) { { styles: %w[large brandColor] } }
      it { should eq(['ApplicationComponent', 'ApplicationComponent--large', 'ApplicationComponent--brandColor']) }
    end
  end

  describe '#attrs' do
    subject { described_class.new(**params).send(:attrs).attrs }
    it { should eq({ class: 'ApplicationComponent' }) }

    context 'with attributes given explicitly' do
      let(:params) { { id: 'my-component' } }
      it { should eq({ class: 'ApplicationComponent', id: 'my-component' }) }
    end
  end
end

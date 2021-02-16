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

  describe '#t' do
    subject { described_class.new(**params).send(:t, key) }

    let(:key) { 'key' }
    let(:scoped_key) { "components.application_component.#{key}" }

    context 'if component-specific translation exists' do
      before do
        allow(I18n).to receive(:exists?).with(scoped_key).and_return(true)
        allow(I18n).to receive(:t).with(scoped_key, {}).and_return('Component translation')
      end

      it { should eq('Component translation') }
    end

    context 'if component-specific translation does not exist' do
      before do
        allow(I18n).to receive(:exists?).with(scoped_key).and_return(false)
        allow(I18n).to receive(:t).with(key, {}).and_return('Global translation')
      end

      it { should eq('Global translation') }
    end
  end
end

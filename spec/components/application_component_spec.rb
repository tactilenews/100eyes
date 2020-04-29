# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationComponent, type: :component do

  describe '#class_names' do
    subject { described_class.new(**params).send(:class_names) }

    let(:params) { {} }
    it { should eq(['ApplicationComponent']) }

    describe 'given a list of styles' do
      let(:params) { { styles: ['large', 'brandColor'] } }
      it { should eq(['ApplicationComponent', 'ApplicationComponent--large', 'ApplicationComponent--brandColor'] ) }
    end
  end

end

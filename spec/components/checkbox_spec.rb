# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Checkbox::Checkbox, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { {} }
  it { should have_css('.Checkbox') }
  it { should_not have_css('.slider.round') }

  describe 'styles: [:switch]' do
    let(:params) { { styles: [:switch] } }
    it { should have_css('.Checkbox.Checkbox--switch') }
    it { should have_css('.Checkbox-slider') }
  end
end

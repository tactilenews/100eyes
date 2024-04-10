# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PageHeader::PageHeader, type: :component do
  subject { render_inline(described_class.new(**params)) { 'Heading' } }

  let(:params) { {} }

  it { is_expected.to have_css('.PageHeader', text: 'Heading') }
  it { is_expected.not_to have_css('.PageHeader-actions') }
  it { is_expected.not_to have_css('.PageHeader-tabBar') }
  it { is_expected.not_to have_css('.PageHeader--tabBar') }

  context 'with tab_bar slot' do
    subject do
      render_inline(described_class.new(**params)) do |component|
        component.tab_bar { 'Tab Bar' }
      end
    end

    it { is_expected.to have_css('.PageHeader--tabBar') }
    it { is_expected.to have_css('.PageHeader-tabBar', text: 'Tab Bar') }
  end
end

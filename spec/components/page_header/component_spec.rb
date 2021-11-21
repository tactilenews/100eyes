# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PageHeader::Component, type: :component do
  subject { render_inline(described_class.new(**params)) { 'Heading' } }

  let(:params) { {} }

  it { should have_css('.PageHeader', text: 'Heading') }
  it { should_not have_css('.PageHeader-actions') }
  it { should_not have_css('.PageHeader-tabBar') }
  it { should_not have_css('.PageHeader--tabBar') }

  context 'with actions slot' do
    subject do
      render_inline(described_class.new(**params)) do |component|
        component.actions { 'Actions' }
      end
    end

    it { should have_css('.PageHeader-actions', text: 'Actions') }
  end

  context 'with tab_bar slot' do
    subject do
      render_inline(described_class.new(**params)) do |component|
        component.tab_bar { 'Tab Bar' }
      end
    end

    it { should have_css('.PageHeader--tabBar') }
    it { should have_css('.PageHeader-tabBar', text: 'Tab Bar') }
  end
end

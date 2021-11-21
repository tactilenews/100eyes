# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Field::Component, type: :component do
  subject { render_inline(described_class.new(**params)) { content } }

  let(:contributor) { build(:contributor) }

  let(:content) { 'Text input' }
  let(:params) { { object: contributor, attr: :name } }

  it { should have_css('.BaseField') }
  it { should have_text('Text input') }
  it { should have_css('.BaseField label[for="contributor[name]"]') }

  before(:each) { allow(I18n).to receive(:t).and_return(nil) }

  describe 'label' do
    context 'with translation' do
      before { allow(I18n).to receive(:t).with('contributor.form.name.label').and_return('Name') }
      it { should have_css('.BaseField label', text: 'Name') }
    end

    context 'with label parameter' do
      let(:params) { { object: contributor, attr: :name, label: 'Custom label' } }
      it { should have_css('.BaseField label', text: 'Custom label') }
    end
  end

  describe 'help text' do
    context 'with translation' do
      before { allow(I18n).to receive(:t).with('contributor.form.name.help', default: nil).and_return('First and last name') }
      it { should have_css('.BaseField-helpText', text: 'First and last name') }
    end

    context 'with help parameter' do
      let(:params) { { object: contributor, attr: :name, help: 'Custom help text' } }
      it { should have_css('.BaseField-helpText', text: 'Custom help text') }
    end
  end

  context 'errors' do
    it { should_not have_css('.BaseField-errorText') }

    context 'with invalid object' do
      let(:contributor) { build(:contributor, email: 'INVALID') }
      let(:params) { { object: contributor, attr: :email } }
      before { contributor.validate }
      it { should have_css('strong.BaseField-errorText', text: 'ist nicht gültig') }
    end
  end
end

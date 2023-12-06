# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BaseField::BaseField, type: :component do
  subject { render_inline(described_class.new(**params)) { content } }

  let(:content) { 'Text input' }
  let(:params) do
    {
      id: 'name',
      label: 'Name',
      help: 'Help text',
      errors: ['Error']
    }
  end

  it { is_expected.to have_css('.BaseField') }
  it { is_expected.to have_text('Text input') }
  it { is_expected.to have_css('.BaseField label[for="name"]', text: 'Name') }
  it { is_expected.to have_css('.BaseField-helpText', text: 'Help text') }
  it { is_expected.to have_css('.BaseField-errorText', text: 'Error') }
end

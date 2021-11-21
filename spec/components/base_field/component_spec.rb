# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BaseField::Component, type: :component do
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

  it { should have_css('.BaseField') }
  it { should have_text('Text input') }
  it { should have_css('.BaseField label[for="name"]', text: 'Name') }
  it { should have_css('.BaseField-helpText', text: 'Help text') }
  it { should have_css('.BaseField-errorText', text: 'Error') }
end

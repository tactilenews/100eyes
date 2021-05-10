# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Callout::Callout, type: :component do
  subject { render_inline(described_class.new(**params)) { content } }

  let(:params) { {} }
  let(:content) { 'Message' }

  it { should have_css('.Callout', text: 'Message') }
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ChatPreview::ChatPreview, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { {} }
  it { should have_css('.ChatPreview') }

  it { should have_css('.ChatPreview-header', text: 'TestingProject') }
end

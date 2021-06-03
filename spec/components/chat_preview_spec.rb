# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ChatPreview::ChatPreview, type: :component do
  subject { render_inline(described_class.new(**params)) }
  before do
    allow(Setting).to receive(:project_name).and_return('TestingProject')
  end

  let(:params) { {} }
  it { should have_css('.ChatPreview') }

  it { should have_css('.ChatPreview-header', text: 'TestingProject') }
end

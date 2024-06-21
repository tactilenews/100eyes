# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ChatPreview::ChatPreview, type: :component do
  subject { render_inline(described_class.new(**params)) }
  let(:organization) { create(:organization, project_name: 'TestingProject') }

  let(:params) { { organization: organization } }
  it { should have_css('.ChatPreview') }

  it { should have_css('.ChatPreview-header', text: 'TestingProject') }
end

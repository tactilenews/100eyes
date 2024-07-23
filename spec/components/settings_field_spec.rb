# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SettingsField::SettingsField, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:organization) { create(:organization) }
  let(:params) { { organization: organization, type: :input, attr: :project_name } }
  it { should have_css('input[id="organization[project_name]"][type="text"]') }
end

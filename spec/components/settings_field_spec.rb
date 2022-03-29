# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SettingsField::SettingsField, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { { type: :input, setting: :project_name } }
  it { should have_css('input[id="setting[project_name]"][type="text"]') }
end

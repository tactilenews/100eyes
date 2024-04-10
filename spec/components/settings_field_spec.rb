# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SettingsField::SettingsField, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { { type: :input, attr: :project_name } }

  it { is_expected.to have_css('input[id="setting[project_name]"][type="text"]') }
end

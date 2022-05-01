# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SettingsFile::SettingsFile, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { { attr: :onboarding_logo } }
  it { should have_css('input[id="setting_files[onboarding_logo]"][type="file"]') }
end

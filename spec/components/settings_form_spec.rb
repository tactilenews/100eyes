# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SettingsForm::SettingsForm, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:current_user) { create(:user) }
  let(:params) { { current_user: current_user } }

  it { is_expected.to have_css('form') }
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SettingsForm::SettingsForm, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:organization) { create(:organization) }
  let(:current_user) { create(:user) }
  let(:params) { { organization: organization, current_user: current_user } }

  it { should have_css('form') }
end

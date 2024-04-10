# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OtpSetup::OtpSetup, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { { user: create(:user) } }

  it { is_expected.to have_css('.OtpSetup') }
end

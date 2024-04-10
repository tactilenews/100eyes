# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NavBar::NavBar, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { { current_user: create(:user) } }

  it { is_expected.to have_css('.NavBar') }
end

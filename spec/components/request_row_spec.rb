# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RequestRow::RequestRow, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:the_request) { create(:request) }
  let(:params) { { request: the_request } }

  it { is_expected.to have_css('.RequestRow') }
end

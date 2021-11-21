# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RequestRow::Component, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:the_request) { create(:request) }
  let(:params) { { request: the_request } }

  it { should have_css('.RequestRow') }
end

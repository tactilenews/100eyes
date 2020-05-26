# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RequestRow::RequestRow, type: :component do
  subject { render_inline(described_class.new(**params), host: 'http://localhost:3000') }

  let(:request) { build(:request) }
  let(:params) { { request: request } }
  pending 'why do we get undefined method `host` on Request?' do
    should have_css('.RequestRow')
  end
end

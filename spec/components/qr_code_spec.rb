# frozen_string_literal: true

require 'rails_helper'

RSpec.describe QrCode::QrCode, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { { url: 'https://example.org' } }

  it { should have_css('.QrCode') }
end

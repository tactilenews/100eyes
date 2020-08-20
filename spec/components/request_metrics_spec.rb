# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RequestMetrics::RequestMetrics, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { { request: request } }
  let(:request) { build(:request) }

  it { should have_text('haben geantwortet') }
  it { should have_text('Nachrichten insgesamt') }
  it { should have_text('Fotos') }
end

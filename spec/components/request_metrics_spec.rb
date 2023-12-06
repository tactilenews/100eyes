# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RequestMetrics::RequestMetrics, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { { request: request } }
  let(:request) { build(:request) }

  it { is_expected.to have_text('haben geantwortet') }
  it { is_expected.to have_text('empfangene Nachrichten') }
  it { is_expected.to have_text('empfangene Bilder') }
end

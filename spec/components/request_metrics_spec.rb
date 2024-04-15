# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RequestMetrics::RequestMetrics, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { { request_for_info: request_for_info } }
  let(:request_for_info) { build(:request) }

  it { should have_text('haben geantwortet') }
  it { should have_text('empfangene Nachrichten') }
  it { should have_text('empfangene Bilder') }
end

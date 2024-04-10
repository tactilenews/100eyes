# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CommunityMetrics::CommunityMetrics, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { { active_contributors_count: 25, requests_count: 200, replies_count: 3_000, engagment_metric: 100.0 } }

  it { is_expected.to have_text('aktive Mitglieder') }
  it { is_expected.to have_text('Fragen gestellt') }
  it { is_expected.to have_text('empfangene Nachrichten') }
  it { is_expected.to have_text('Interaktionsquote') }
end

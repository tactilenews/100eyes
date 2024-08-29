# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CommunityMetrics::CommunityMetrics, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:params) { { active_contributors_count: 25, requests_count: 200, replies_count: 3_000, engagement_metric: 100.0 } }

  it { should have_text('aktive Mitglieder') }
  it { should have_text('Fragen gestellt') }
  it { should have_text('empfangene Nachrichten') }
  it { should have_text('Interaktionsquote') }
end

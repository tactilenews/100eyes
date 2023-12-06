# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RequestsFeed::RequestsFeed, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:contributor) { create(:contributor) }
  let(:params) { { contributor: contributor } }

  it { is_expected.to have_css('.RequestsFeed') }
  it { is_expected.to have_text('hat bisher auf keine Recherche geantwortet') }

  context 'given a contributor with replies' do
    let!(:reply) { create(:message, sender: contributor, request: create(:request, title: 'Lorem Ipsum')) }

    it { is_expected.to have_link('Lorem Ipsum', href: "/requests/#{reply.request.id}#contributor-#{contributor.id}") }
  end
end

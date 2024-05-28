# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RequestsFeed::RequestsFeed, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:contributor) { create(:contributor) }
  let(:params) { { contributor: contributor } }

  it { should have_css('.RequestsFeed') }
  it { should have_text('hat bisher auf keine Recherche geantwortet') }

  context 'given a contributor with replies' do
    let!(:reply) { create(:message, sender: contributor, request: create(:request, title: 'Lorem Ipsum')) }
    it { should have_link('Lorem Ipsum', href: "/requests/#{reply.request.id}#message-#{reply.id}") }
  end
end

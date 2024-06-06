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

    it 'should have a link to the reply' do
      should have_link('Lorem Ipsum', href: conversations_contributor_path(id: contributor.id, anchor: "message-#{reply.id}"))
    end

    it 'should have a link to the conversations' do
      should have_link(
        I18n.t('components.requests_feed.show_all',
               count: contributor.replies.count),
        href: conversations_contributor_path(id: contributor.id)
      )
    end
  end
end

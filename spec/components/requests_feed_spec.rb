# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RequestsFeed::RequestsFeed, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:organization) { create(:organization) }
  let(:contributor) { create(:contributor, organization: organization) }
  let(:params) { { contributor: contributor, organization: organization } }

  it { should have_css('.RequestsFeed') }
  it { should have_text('hat bisher auf keine Recherche geantwortet') }

  context 'given a contributor with replies' do
    # Never use 'let(:request)' as this will lead to weird errors.
    let(:message_request) { create(:request, title: 'Lorem Ipsum', organization: organization) }
    let!(:reply) { create(:message, sender: contributor, request: message_request) }

    it 'should have a link to the reply' do
      should have_link('Lorem Ipsum',
                       href: conversations_organization_contributor_path(organization, contributor, anchor: "message-#{reply.id}"))
    end

    it 'should have a link to the conversations' do
      should have_link(
        I18n.t('components.requests_feed.show_all',
               count: contributor.replies.count),
        href: conversations_organization_contributor_path(contributor.organization, contributor)
      )
    end
  end
end

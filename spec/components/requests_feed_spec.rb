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

    describe '#most_recent_replies_to_some_request' do
      subject { described_class.new(**params).send(:most_recent_reply_to_each_request) }

      let(:old_date) { ActiveSupport::TimeZone['Berlin'].parse('2011-04-12 2pm') }
      let(:old_message) { create(:message, created_at: old_date, sender: contributor, request: message_request) }
      let(:another_request) { create(:request) }
      let(:old_request) { create(:request, created_at: (old_date - 1.day)) }
      let(:message_without_a_request) { create(:message, sender: contributor, request: nil) }

      before(:each) do
        create_list(:message, 3, sender: contributor, request: message_request)
        create(:message, sender: contributor, request: old_request)
        create(:message, sender: contributor, request: another_request)
        old_message
        message_without_a_request
      end

      it { expect(subject.length).to eq(3) }

      it 'chooses one reply per request' do
        expect(subject.map(&:request)).to match_array([message_request, another_request, old_request])
      end

      it 'orders replies chronologically in descending order' do
        expect(subject).to eq(subject.sort_by(&:created_at).reverse)
      end

      it 'returns only replies attached to a request' do
        expect(subject).not_to include(message_without_a_request)
      end

      describe 'number of database calls' do
        subject { -> { described_class.new(**params).send(:most_recent_reply_to_each_request).first.request } }
        it { should make_database_queries(count: 2) }
      end
    end
  end
end

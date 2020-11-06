# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RepliesMailbox, type: :mailbox do
  subject { -> { receive_inbound_email_from_mail params } }

  let(:from_address) { 'zora@example.org' }
  let(:params) { { from: from_address, body: 'Meiner Katze geht es gut!' } }

  it { should_not(change { Message.count }) }

  it {
    should have_enqueued_job.on_queue('mailers').with(
      'Mailer',
      'user_not_found_email',
      'deliver_now',
      {
        params: { email: 'zora@example.org' },
        args: []
      }
    )
  }

  describe 'given a user' do
    let(:user) { create(:user, email: 'zora@example.org') }
    before(:each) { user }

    it { should_not(change { Message.count }) }

    describe 'given an active request' do
      let(:request) { create(:request, title: 'Wie geht es euren Haustieren in Corona-Zeiten?') }
      before(:each) { create(:message, request: request, sender: nil, recipient: user) }

      it { should(change { Message.count }.from(1).to(2)) }

      describe 'after email processing' do
        let(:replies) { Message.where(sender: user).pluck(:text) }

        before(:each) { subject.call }

        it { should(change { Message.count }.from(2).to(3)) }

        describe 'with matching from address' do
          let(:from_address) { 'zora@example.org' }

          it 'assigns sender' do
            expect(replies).to contain_exactly('Meiner Katze geht es gut!')
          end
        end

        describe 'with uppercase from address' do
          let(:from_address) { 'ZORA@EXAMPLE.ORG' }

          it 'assigns sender' do
            expect(replies).to contain_exactly('Meiner Katze geht es gut!')
          end
        end

        describe 'with multiple from addresses' do
          let(:from_address) { ['other@example.org', 'zora@example.org'] }

          it 'assigns sender' do
            expect(replies).to contain_exactly('Meiner Katze geht es gut!')
          end
        end
      end
    end
  end
end

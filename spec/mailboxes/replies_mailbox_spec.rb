# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RepliesMailbox, type: :mailbox do
  subject { -> { receive_inbound_email_from_mail params } }
  let(:params) do
    {
      to: 'feedback@100eyes.de',
      from: 'till@example.org',
      subject: 'AW: Haustiere und Corona',
      body: <<~BODY
        Meiner Katze geht's gut!
      BODY
    }
  end

  it { should_not(change { Message.count }) }
  it {
    should have_enqueued_job.on_queue('mailers').with(
      'ReplyMailer',
      'user_not_found_email',
      'deliver_now',
      {
        params: { email: 'till@example.org' },
        args: []
      }
    )
  }

  describe 'given a user with a corresponding email' do
    let(:user) { create(:user, id: 3, first_name: 'Till', email: 'till@example.org') }
    before(:each) { user }
    it { should_not(change { Message.count }) }

    describe 'and an active request' do
      let(:the_request) { create(:request, title: 'Wie geht es euren Haustieren in Corona-Zeiten?') }
      before(:each) { create(:message, request: the_request, sender: nil, recipient: user) }
      it { should(change { Message.count }.from(1).to(2)) }
      describe 'after the email is processed' do
        before(:each) { subject.call }
        it 'sender is assigned' do
          expect(Message.pluck(:sender_id)).to match_array([3, nil])
        end
      end
    end
  end
end

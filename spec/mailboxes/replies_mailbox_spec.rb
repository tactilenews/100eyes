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
    before { User.create!(first_name: 'Till', email: 'till@example.org') }
    it { should_not(change { Message.count }) }

    describe 'and a recent request' do
      before { Request.create!(title: 'Wie geht es euren Haustieren in Corona-Zeiten?') }
      it { should(change { Message.count }.by(1)) }
      it 'assigns message to user' do
        subject.call
        expect(Message.first.user.first_name).to eq('Till')
      end
    end
  end
end

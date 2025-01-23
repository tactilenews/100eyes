# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RepliesMailbox, type: :mailbox do
  subject { -> { receive_inbound_email_from_mail(**params) } }

  let(:organization) { create(:organization) }
  let(:from_address) { 'zora@example.org' }
  let(:params) { { from: from_address, body: 'Meiner Katze geht es gut!', to: organization.email_from_address } }

  it { should_not(change { Message.count }) }

  it {
    should have_enqueued_job.on_queue('default').with(
      'PostmarkAdapter::Outbound',
      'bounce_email',
      'deliver_now',
      {
        params: {
          organization: organization,
          text: /Vielen Dank für Ihre Nachricht. Leider konnten wir Ihre E-Mail-Adresse nicht zuordnen./,
          mail: { subject: 'Wir können Ihre E-Mail Adresse nicht zuordnen', message_stream: 'outbound', to: 'zora@example.org' }
        },
        args: []
      }
    )
  }

  describe 'given a contributor' do
    let(:contributor) { create(:contributor, email: 'zora@example.org', organization: organization) }
    before(:each) { contributor }

    it 'saves the message' do
      expect { subject.call }.to change(Message, :count).by(1)
    end

    describe 'given an active request' do
      let(:request) { create(:request, title: 'Wie geht es euren Haustieren in Corona-Zeiten?', organization: organization) }
      before(:each) { create(:message, request: request, sender: nil, recipient: contributor, broadcasted: true) }
      let!(:admin) { create(:user, admin: true) }

      it { should(change { Message.count }.from(1).to(2)) }

      describe 'after email processing' do
        let(:replies) { Message.where(sender: contributor).pluck(:text) }

        before do
          organization.update!(users: create_list(:user, 5))
          subject.call
        end

        it { should(change { Message.count }.from(2).to(3)) }

        it 'it creates a MessageReceived notification for each user and admin' do
          subject.call
          recipient_ids = ActivityNotification.where(type: MessageReceived.name).pluck(:recipient_id).uniq.sort
          user_ids = organization.users.pluck(:id)
          admin_id = admin.id
          ids = (user_ids << admin_id).sort
          expect(recipient_ids).to eq(ids)
        end

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

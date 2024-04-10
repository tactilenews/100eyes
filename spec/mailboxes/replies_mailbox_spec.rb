# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RepliesMailbox, type: :mailbox do
  subject { -> { receive_inbound_email_from_mail(**params) } }

  let(:from_address) { 'zora@example.org' }
  let(:params) { { from: from_address, body: 'Meiner Katze geht es gut!' } }

  it { is_expected.not_to(change(Message, :count)) }

  it {
    expect(subject).to have_enqueued_job.on_queue('default').with(
      'PostmarkAdapter::Outbound',
      'bounce_email',
      'deliver_now',
      {
        params: {
          text: /Vielen Dank für Ihre Nachricht. Leider konnten wir Ihre E-Mail-Adresse nicht zuordnen./,
          mail: { subject: 'Wir können Ihre E-Mail Adresse nicht zuordnen', message_stream: 'outbound', to: 'zora@example.org' }
        },
        args: []
      }
    )
  }

  describe 'given a contributor' do
    let(:contributor) { create(:contributor, email: 'zora@example.org') }

    before { contributor }

    it { is_expected.not_to(change(Message, :count)) }

    describe 'given an active request' do
      let(:request) { create(:request, title: 'Wie geht es euren Haustieren in Corona-Zeiten?') }

      before { create(:message, request: request, sender: nil, recipient: contributor, broadcasted: true) }

      it { is_expected.to(change(Message, :count).from(1).to(2)) }

      describe 'after email processing' do
        let(:replies) { Message.where(sender: contributor).pluck(:text) }

        before { subject.call }

        it { is_expected.to(change(Message, :count).from(2).to(3)) }

        describe 'MessageReceived ActivityNotification' do
          context 'creates an ActivityNotification' do
            it_behaves_like 'an ActivityNotification', 'MessageReceived'
          end
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

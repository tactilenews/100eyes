# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ThreemaAdapter::Outbound::Text do
  let(:adapter) { described_class.new }
  let(:threema_id) { 'V5EA564T' }
  let(:organization) do
    create(:organization, threemarb_api_identity: '*100EYES', threemarb_api_secret: 'valid_secret', threemarb_private: 'valid_private')
  end
  let(:contributor) { create(:contributor, :skip_validations, threema_id: threema_id, email: nil, organization: organization) }
  let(:message) { create(:message, recipient: contributor) }
  let(:organization_id) { organization.id }
  let(:contributor_id) { contributor.id }
  let(:threema_double) { instance_double(Threema) }
  let(:threema_lookup_double) { instance_double(Threema::Lookup) }
  let(:message_id) { SecureRandom.alphanumeric(16) }

  before do
    allow(Threema).to receive(:new).and_return(threema_double)
    allow(Threema::Lookup).to receive(:new).and_call_original
    allow(Threema::Lookup).to receive(:new).with({ threema: threema_double }).and_return(threema_lookup_double)
    allow(threema_lookup_double).to receive(:key).and_return('PUBLIC_KEY_HEX_ENCODED')
    allow(threema_double).to receive(:send).with(type: :text, threema_id: threema_id, text: message.text).and_return(message_id)
  end

  describe '#perform' do
    subject { -> { adapter.perform(contributor_id: contributor_id, text: message.text) } }

    it 'sends the message' do
      expect(threema_double).to receive(:send).with(type: :text, threema_id: threema_id, text: message.text)

      subject.call
    end

    context 'with lowercase Threema ID' do
      let(:threema_id) { 'v5ea564t' }

      it 'converts ID to uppercase' do
        expect(threema_double).to receive(:send).with(type: :text, threema_id: threema_id.upcase, text: message.text)

        subject.call
      end
    end

    context 'when a message is passed in' do
      subject do
        lambda {
          adapter.perform(contributor_id: contributor_id, text: message.text, message: message)
        }
      end

      it "saves the returned message id to the message's external_id" do
        expect { subject.call }.to change { message.reload.external_id }.from(nil).to(message_id)
      end

      it 'saves the current time as sent_at' do
        expect { subject.call }.to change { message.reload.sent_at }.from(nil).to be_within(1.second).of(Time.current)
      end
    end

    describe 'Unknown contributor' do
      let(:contributor_id) { 564_321 }

      it 'throws an error' do
        expect { subject.call }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    describe 'Invalid threema ID' do
      let(:invalid_threema_error) { RuntimeError.new("Can't find public key for Threema ID #{threema_id}") }
      before do
        allow(threema_double).to receive(:send).with(type: :text, threema_id: threema_id,
                                                     text: message.text).and_raise(invalid_threema_error)
      end

      it 'enqueues a job to mark inactive contributor inactive' do
        expect { subject.call }.to have_enqueued_job(MarkInactiveContributorInactiveJob).with(
          contributor_id: contributor.id
        )
      end

      it 'reports the error' do
        expect(Sentry).to receive(:capture_exception).with(invalid_threema_error)

        subject.call
      end
    end
  end
end

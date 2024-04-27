# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ThreemaAdapter::Outbound::Text do
  let(:adapter) { described_class.new }
  let(:threema_id) { 'V5EA564T' }
  let(:contributor) do
    build(:contributor, threema_id: threema_id, email: nil).tap { |contributor| contributor.save(validate: false) }
  end
  let(:message) { create(:message, recipient: contributor) }
  let(:threema_double) { instance_double(Threema) }
  let(:threema_lookup_double) { instance_double(Threema::Lookup) }
  let(:message_id) { SecureRandom.alphanumeric(16) }

  before do
    allow(ThreemaAdapter::Outbound::Text).to receive(:threema_instance).and_return(threema_double)
    allow(Threema::Lookup).to receive(:new).and_call_original
    allow(Threema::Lookup).to receive(:new).with({ threema: threema_double }).and_return(threema_lookup_double)
    allow(threema_lookup_double).to receive(:key).and_return('PUBLIC_KEY_HEX_ENCODED')
    allow(threema_double).to receive(:send).with(type: :text, threema_id: threema_id, text: message.text).and_return(message_id)
  end

  describe '#perform' do
    subject { -> { adapter.perform(text: message.text, contributor_id: message.recipient.id) } }

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
      subject { -> { adapter.perform(text: message.text, contributor_id: message.recipient.id, message: message) } }

      it "saves the returned message id to the message's external_id" do
        expect { subject.call }.to change { message.reload.external_id }.from(nil).to(message_id)
      end
    end
  end
end

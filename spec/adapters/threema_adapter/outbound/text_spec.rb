# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ThreemaAdapter::Outbound::Text do
  let(:adapter) { described_class.new }
  let(:threema_id) { 'V5EA564T' }
  let(:contributor) do
    build(:contributor, threema_id: threema_id, email: nil).tap { |contributor| contributor.save(validate: false) }
  end
  let(:message) { create(:message, recipient: contributor) }

  describe '#perform' do
    subject { -> { adapter.perform(text: message.text, recipient: message.recipient) } }

    it 'sends the message' do
      expect_any_instance_of(Threema).to receive(:send).with(type: :text, threema_id: 'V5EA564T', text: message.text)
      subject.call
    end

    context 'with lowercase Threema ID' do
      let(:threema_id) { 'v5ea564t' }

      it 'converts ID to uppercase' do
        expect_any_instance_of(Threema).to receive(:send).with(type: :text, threema_id: 'V5EA564T', text: message.text)
        subject.call
      end
    end
  end
end

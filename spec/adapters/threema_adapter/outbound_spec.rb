# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ThreemaAdapter::Outbound do
  let(:adapter) { described_class.new }
  let(:threema) { instance_double(Threema) }
  let(:contributor) { create(:contributor, threema_id: 'V5EA564T') }
  let(:message) { create(:message, recipient: contributor) }

  before do
    allow(Threema).to receive(:new).and_return(threema)
  end

  describe '#perform' do
    subject { adapter.perform(text: message.text, recipient: message.recipient) }

    it 'sends the message' do
      expect(threema).to receive(:send).with({ type: :text, threema_id: contributor.threema_id, text: message.text })

      subject
    end
  end
end

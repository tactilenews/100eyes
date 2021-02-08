# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ThreemaAdapter do
  let(:adapter) { described_class.new(message: message) }
  let(:threema) { instance_double(Threema) }
  let(:contributor) { create(:contributor, threema_id: 'V5EA564T') }
  let(:message) { build(:message, recipient: contributor) }

  before do
    allow(Threema).to receive(:new).and_return(threema)
  end

  describe '#send!' do
    subject { adapter.send! }

    it 'sends the message' do
      expect(threema).to receive(:send).with({ type: :text, threema_id: contributor.threema_id, text: message.text })

      subject
    end
  end
end

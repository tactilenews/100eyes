# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ThreemaMessage do
  before { create(:contributor, threema_id: 'V5EA564T') }

  let(:threema_message) { described_class.new(message) }
  let(:message) do
    ActionController::Parameters.new({
                                       'from' => 'V5EA564T',
                                       'to' => '*100EYES',
                                       'messageId' => 'dfbe859c44f15125',
                                       'date' => '1612808574',
                                       'nonce' => 'b1c80cf818e289e6b1966b9bcab6fb9fb5e31862b46d8f98',
                                       'box' => 'ENCRYPTED FILE',
                                       'mac' => '8c58e9d4d9ad1aa960a58a1f11bcf712e9fcd50319778762824d8259dcbdc639',
                                       'nickname' => 'matt.rider'
                                     })
  end
  let(:threema_mock) { instance_double(Threema::Receive::Text, content: 'Hello World!') }
  let(:threema) { instance_double(Threema) }

  before do
    allow(Threema).to receive(:new).and_return(threema)
    allow(threema).to receive(:receive).with({ payload: message }).and_return(threema_mock)
  end

  describe '#text' do
    before do
      allow(Threema).to receive(:new).and_return(threema)
      allow(threema).to receive(:receive).with({ payload: message }).and_return(threema_mock)
    end

    subject { threema_message.message.text }

    it { is_expected.to eq('Hello World!') }

    describe 'saving the message' do
      subject { threema_message.message.raw_data }
      it { should be_attached }
    end
  end

  describe 'Unknown content' do
    subject { threema_message.unknown_content }

    before do
      allow(Threema).to receive(:new).and_return(threema)
      allow(threema).to receive(:receive).with({ payload: message }).and_return(threema_mock)
      allow(threema_mock).to receive(:is_a?).and_return(true)
    end

    context 'Threema::Receive::File' do
      let(:threema_mock) { instance_double(Threema::Receive::File, name: 'my voice', content: 'x\00x\\0', mime_type: 'audio/acc') }

      it { is_expected.to be(true) }
    end

    context 'Threema::Receive::Image' do
      let(:threema_mock) { instance_double(Threema::Receive::Image, content: 'x\00x\\0') }

      it { is_expected.to be(true) }
    end

    context 'Threema::Receive::DeliveryReceipt' do
      let(:threema_mock) { instance_double(Threema::Receive::DeliveryReceipt, content: 'x\00x\\0') }

      it { is_expected.to be(true) }
    end
  end
end

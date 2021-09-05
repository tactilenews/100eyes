# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ThreemaAdapter::Inbound do
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
    allow(threema_mock).to receive(:instance_of?) { false }
  end

  describe 'DeliveryReceipt' do
    subject { threema_message.delivery_receipt }

    before { allow(threema_mock).to receive(:instance_of?).with(Threema::Receive::DeliveryReceipt).and_return(true) }

    context 'Threema::Receive::DeliveryReceipt' do
      let(:threema_mock) { instance_double(Threema::Receive::DeliveryReceipt, content: 'x\00x\\0') }

      it { is_expected.to be(true) }
    end
  end

  describe '#text' do
    before { allow(threema_mock).to receive(:instance_of?).with(Threema::Receive::Text).and_return(true) }

    subject { threema_message.message.text }

    it { is_expected.to eq('Hello World!') }

    describe 'saving the message' do
      subject { threema_message.message.raw_data }
      it { should be_attached }
    end
  end

  describe 'Threema::Receive::File' do
    let(:threema_mock) { instance_double(Threema::Receive::File, name: 'my voice', content: 'x\00x\\0', mime_type: 'audio/aac') }
    before { allow(threema_mock).to receive(:instance_of?).with(Threema::Receive::File).and_return(true) }

    describe '#file' do
      let(:file) { threema_message.message.files.first }
      subject { file.attachment }

      describe 'handling different content types' do

        context 'audio' do
          it { should be_attached }

          it 'preserves the content_type' do
            expect(subject.blob.content_type).to eq('audio/aac')
          end
        end

        context 'image' do
          let(:threema_mock) { instance_double(Threema::Receive::File, name: 'my image', content: 'x\00x\\0', mime_type: 'image/jpeg') }

          it { should be_attached }
          it 'preserves the content_type' do
            expect(subject.blob.content_type).to eq('image/jpeg')
          end
        end
      end
    end

    describe 'saving the message' do
      subject do
        lambda do
          threema_message.message.request = create(:request)
          threema_message.message.save!
        end
      end
      it { should change { ActiveStorage::Attachment.where(record_type: 'Message::File').count }.from(0).to(1) }
    end
  end

  describe 'Unknown content' do
    subject { threema_message.unknown_content }

    context 'Threema::Receive::Image' do
      let(:threema_mock) { instance_double(Threema::Receive::Image, content: 'x\00x\\0') }
      before { allow(threema_mock).to receive(:instance_of?).with(Threema::Receive::Image).and_return(true) }

      it { is_expected.to be(true) }
    end

    describe 'Threema::Receive::File' do
      before do
        allow(threema_mock).to receive(:instance_of?).with(Threema::Receive::File).and_return(true)
        allow(threema_mock).to receive(:respond_to?).with(:mime_type).and_return(true)
      end

      context 'Video files' do
        let(:threema_mock) { instance_double(Threema::Receive::File, name: 'my video', content: 'x\00x\\0', mime_type: 'video/mp4') }

        it { is_expected.to be(true) }
      end

      context 'Pdf files' do
        let(:threema_mock) { instance_double(Threema::Receive::File, name: 'my pdf', content: 'x\00x\\0', mime_type: 'application/pdf') }

        it { is_expected.to be(true) }
      end

      context 'Contact' do
        let(:threema_mock) do
          instance_double(Threema::Receive::File, name: "my friend's contact", content: 'x\00x\\0', mime_type: 'text/x-vcard')
        end

        it { is_expected.to be(true) }
      end

      context 'Word doc' do
        let(:threema_mock) do
          instance_double(Threema::Receive::File, name: "my friend's contact", content: 'x\00x\\0', mime_type: 'application/msword')
        end

        it { is_expected.to be(true) }
      end
    end
  end
end

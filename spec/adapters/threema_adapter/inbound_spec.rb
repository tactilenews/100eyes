# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ThreemaAdapter::Inbound do
  let(:threema_id) { 'V5EA564T' }
  let(:organization) { create(:organization, threemarb_api_identity: '*100EYES') }
  let!(:contributor) { create(:contributor, :skip_validations, threema_id: threema_id, organization: organization) }

  let(:adapter) { described_class.new }
  let(:threema_message) do
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
  let(:messages) { [create(:message, external_id: SecureRandom.alphanumeric(16))] }
  let(:message_ids) { messages.pluck(:external_id) }
  let(:status) { :received }
  let(:timestamp) { Time.current.to_i }

  before do
    allow(Threema).to receive(:new).and_return(threema)
    allow(threema).to receive(:receive).with({ payload: threema_message }).and_return(threema_mock)
    allow(threema_mock).to receive(:instance_of?) { false }
  end

  describe '#consume' do
    let(:message) do
      adapter.consume(threema_message) do |message|
        return message
      end
    end

    before { allow(threema_mock).to receive(:instance_of?).with(Threema::Receive::Text).and_return(true) }

    describe 'DeliveryReceipt' do
      subject { message }

      before { allow(threema_mock).to receive(:instance_of?).with(Threema::Receive::DeliveryReceipt).and_return(true) }

      context 'Threema::Receive::DeliveryReceipt' do
        let(:threema_mock) do
          instance_double(
            Threema::Receive::DeliveryReceipt, content: 'x\00x\\0', message_ids: message_ids, status: status, timestamp: timestamp
          )
        end

        it { is_expected.to be(nil) }
      end
    end

    describe '|message|raw_data' do
      subject { message.raw_data }

      it { is_expected.to be_attached }
    end

    describe '#sender' do
      subject { message.sender }

      it { is_expected.to eq(contributor) }

      context 'if contributor has lowercase Threema ID' do
        let(:threema_id) { 'v5ea564t' }
        it { is_expected.to eq(contributor) }
      end
    end

    describe 'Threema::Receive::File' do
      let(:threema_mock) do
        instance_double(Threema::Receive::File, name: 'my voice', content: 'x\00x\\0', mime_type: 'audio/aac', caption: 'some caption')
      end
      before do
        allow(threema_mock).to receive(:instance_of?).with(Threema::Receive::Text).and_return(false)
        allow(threema_mock).to receive(:instance_of?).with(Threema::Receive::File).and_return(true)
      end

      describe '#file' do
        let(:file) { message.files.first }
        subject { file.attachment }

        describe 'handling different content types' do
          context 'audio' do
            it { should be_attached }

            it 'preserves the content_type' do
              expect(subject.blob.content_type).to eq('audio/aac')
            end
          end

          context 'image' do
            let(:threema_mock) do
              instance_double(Threema::Receive::File, name: 'my image', content: 'x\00x\\0', mime_type: 'image/jpeg', caption: nil)
            end

            it { should be_attached }
            it 'preserves the content_type' do
              expect(subject.blob.content_type).to eq('image/jpeg')
            end
          end

          context 'video' do
            let(:threema_mock) do
              instance_double(Threema::Receive::File, name: 'my video', content: 'x\00x\\0', mime_type: 'video/mp4',
                                                      caption: 'look at this cool video')
            end

            it { should be_attached }
            it 'preserves the content_type' do
              expect(subject.blob.content_type).to eq('video/mp4')
            end
          end
        end
      end

      describe 'saving the caption' do
        subject { message.text }

        it { is_expected.to eq('some caption') }
      end

      describe 'saving the message' do
        subject do
          lambda do
            message.request = create(:request)
            message.save!
          end
        end
        it { should change { ActiveStorage::Attachment.where(record_type: 'Message::File').count }.from(0).to(1) }
      end
    end

    describe 'Unsupported content' do
      subject { message.unknown_content }

      describe 'Threema::Receive::File' do
        before do
          allow(threema_mock).to receive(:instance_of?).with(Threema::Receive::File).and_return(true)
          allow(threema_mock).to receive(:respond_to?).with(:mime_type).and_return(true)
        end

        context 'Pdf files' do
          let(:threema_mock) do
            instance_double(Threema::Receive::File, name: 'my pdf', content: 'x\00x\\0', mime_type: 'application/pdf',
                                                    caption: 'do you accept pdf?')
          end

          it { is_expected.to be(true) }
        end

        context 'Contact' do
          let(:threema_mock) do
            instance_double(Threema::Receive::File, name: "my friend's contact", content: 'x\00x\\0', mime_type: 'text/x-vcard',
                                                    caption: nil)
          end

          it { is_expected.to be(true) }
        end

        context 'Word doc' do
          let(:threema_mock) do
            instance_double(Threema::Receive::File, name: "my friend's contact", content: 'x\00x\\0', mime_type: 'application/msword',
                                                    caption: nil)
          end

          it { is_expected.to be(true) }
        end
      end
    end
  end

  describe '#on' do
    describe 'UNKNOWN_CONTRIBUTOR' do
      let(:unknown_contributor_callback) { spy('unknown_contributor_callback') }

      before do
        adapter.on(ThreemaAdapter::UNKNOWN_CONTRIBUTOR) do |threema_id|
          unknown_contributor_callback.call(threema_id)
        end
      end

      subject do
        adapter.consume(threema_message)
        unknown_contributor_callback
      end

      describe 'if the sender is a contributor ' do
        it { is_expected.not_to have_received(:call) }
      end

      describe 'if the sender is unknown' do
        before { threema_message[:from] = 'NOT_KNOWN' }
        it { is_expected.to have_received(:call).with('NOT_KNOWN') }
      end
    end

    describe 'UNSUBSCRIBE_CONTRIBUTOR' do
      let(:unsubscribe_contributor_callback) { spy('unsubscribe_contributor_callback') }

      before do
        allow(threema_mock).to receive(:instance_of?).with(Threema::Receive::Text).and_return(true)
        adapter.on(ThreemaAdapter::UNSUBSCRIBE_CONTRIBUTOR) do |contributor|
          unsubscribe_contributor_callback.call(contributor)
        end
      end

      subject do
        adapter.consume(threema_message)
        unsubscribe_contributor_callback
      end

      context 'any text other than the keyword Abbestellen' do
        it { is_expected.not_to have_received(:call) }
      end

      context 'with keyword Abbestellen' do
        let(:threema_mock) { instance_double(Threema::Receive::Text, content: 'Abbestellen') }

        it { is_expected.to have_received(:call) }
      end
    end

    describe 'RESUBSCRIBE_CONTRIBUTOR' do
      let(:resubscribe_contributor_callback) { spy('resubscribe_contributor_callback') }

      before do
        allow(threema_mock).to receive(:instance_of?).with(Threema::Receive::Text).and_return(true)
        adapter.on(ThreemaAdapter::RESUBSCRIBE_CONTRIBUTOR) do |contributor|
          resubscribe_contributor_callback.call(contributor)
        end
      end

      subject do
        adapter.consume(threema_message)
        resubscribe_contributor_callback
      end

      context 'any text other than the keyword Bestellen' do
        it { is_expected.not_to have_received(:call) }
      end

      context 'with keyword Bestellen' do
        let(:threema_mock) { instance_double(Threema::Receive::Text, content: 'Bestellen') }

        it { is_expected.to have_received(:call) }
      end
    end

    describe 'UNSUPPORTED_CONTENT' do
      let(:unsupported_content_callback) { spy('unsupported_content_callback') }

      before do
        adapter.on(ThreemaAdapter::UNSUPPORTED_CONTENT) do |contributor|
          unsupported_content_callback.call(contributor)
        end
      end

      subject do
        adapter.consume(threema_message)
        unsupported_content_callback
      end

      context 'if the message is a plaintext message' do
        it { is_expected.not_to have_received(:call) }
      end

      describe 'non-text message' do
        before { allow(threema_mock).to receive(:respond_to?).with(:mime_type).and_return(true) }

        context 'Threema::Receive::NotImplementedFallback' do
          before do
            allow(threema_mock).to receive(:instance_of?).with(Threema::Receive::NotImplementedFallback).and_return(true)
          end

          it { is_expected.to have_received(:call).with(contributor) }
        end

        context 'Pdf files' do
          let(:threema_mock) do
            instance_double(Threema::Receive::File, name: 'my pdf', content: 'x\00x\\0', mime_type: 'application/pdf',
                                                    caption: 'do you accept pdf?')
          end

          it { is_expected.to have_received(:call).with(contributor) }
        end

        context 'Contact' do
          let(:threema_mock) do
            instance_double(Threema::Receive::File, name: "my friend's contact", content: 'x\00x\\0', mime_type: 'text/x-vcard',
                                                    caption: nil)
          end

          it { is_expected.to have_received(:call).with(contributor) }
        end

        context 'Word doc' do
          let(:threema_mock) do
            instance_double(Threema::Receive::File, name: "my friend's contact", content: 'x\00x\\0', mime_type: 'application/msword',
                                                    caption: nil)
          end

          it { is_expected.to have_received(:call).with(contributor) }
        end
      end
    end

    describe 'HANDLE_DELIVERY_RECEIPT' do
      let(:handle_delivery_receipt_callback) { spy('handle_delivery_receipt_callback') }
      let(:threema_mock) do
        instance_double(
          Threema::Receive::DeliveryReceipt, content: 'x\00x\\0', message_ids: message_ids, status: status, timestamp: timestamp
        )
      end

      before do
        allow(threema_mock).to receive(:instance_of?).with(Threema::Receive::DeliveryReceipt).and_return(true)
        adapter.on(ThreemaAdapter::HANDLE_DELIVERY_RECEIPT) do |delivery_receipt|
          handle_delivery_receipt_callback.call(delivery_receipt)
        end
      end

      subject do
        adapter.consume(threema_message)
        handle_delivery_receipt_callback
      end

      describe 'if the message is a delivery receipt' do
        it { should have_received(:call) }
      end
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SignalAdapter::Inbound do
  let(:adapter) { described_class.new }
  let(:signal_message) do
    {
      envelope: {
        source: '+4912345789',
        sourceDevice: 2,
        timestamp: 1_626_708_555_697,
        dataMessage: {
          timestamp: 1_626_708_555_697,
          message: 'Hello 100eyes',
          expiresInSeconds: 0,
          viewOnce: false,
          mentions: [],
          attachments: [],
          contacts: []
        }
      }
    }
  end

  let(:receipt_message) do
    {
      envelope: {
        source: '+4912345789',
        sourceDevice: 1,
        timestamp: 1_626_711_330_462,
        receiptMessage: {
          when: 1_626_711_330_462,
          isDelivery: true,
          isRead: false,
          timestamps: [
            1_626_711_326_111
          ]
        }
      }
    }
  end

  before { contributor }
  let(:contributor) { create(:contributor, id: 4711, phone_number: '+4912345789') }

  describe '#consume' do
    let(:message) do
      adapter.consume(signal_message) do |message|
        return message
      end
    end

    describe '|message| block argument' do
      subject { message }
      it { should be_a(Message) }

      context 'contributor not found' do
        let(:contributor) { create(:contributor, phone_number: '+49555555') }

        it { should be(nil) }
      end

      context 'receipt message' do
        let(:signal_message) { receipt_message }

        it { should be(nil) }
      end
    end

    describe '|message|text' do
      subject { message.text }

      describe 'given a signal_message with a `message`' do
        it { should eq('Hello 100eyes') }
      end
    end

    describe '|message|raw_data' do
      subject { message.raw_data }
      it { should be_attached }
    end

    describe '#sender' do
      subject { message.sender }

      it { should eq(Contributor.find(4711)) }
    end
  end
end

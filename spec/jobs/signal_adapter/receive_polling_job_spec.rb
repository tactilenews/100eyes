# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SignalAdapter::ReceivePollingJob, type: :job do
  describe '#perform_later' do
    subject { -> { described_class.perform_later } }
    it 'enqueues a job' do
      should have_enqueued_job
    end
  end
  describe 'performing enqueued jobs' do
    subject do
      lambda {
        perform_enqueued_jobs do
          described_class.perform_now
        end
      }
    end

    describe 'without a phone number' do
      before do
        allow(Setting).to receive(:signal_phone_number).and_return(nil)
      end

      it 'stops immediately as there are no messages to receive' do
        should_not raise_error
      end
    end

    describe 'given a phone number', vcr: { cassette_name: :receive_signal_messages } do
      before do
        allow(Setting).to receive(:signal_phone_number).and_return('SIGNAL_PHONE_NUMBER') unless Setting.signal_phone_number
      end

      it 'does not crash' do
        should_not raise_error
      end

      describe 'given a request' do
        before { create(:request) }
        it 'does not create messages' do
          should_not(change { Message.count })
        end

        describe 'and a corresponding contributor' do
          before do
            create(:contributor, phone_number: '+4915112345789')
            create(:contributor, phone_number: '+4915155555555')
          end

          it 'create a message' do
            should(change { Message.count }.from(0).to(1))
          end

          it 'assigns the correct contributor' do
            subject.call
            expect(Message.first.contributor.phone_number).to eq('+4915112345789')
          end
        end
      end
    end
  end
end

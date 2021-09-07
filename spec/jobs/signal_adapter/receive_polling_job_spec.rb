# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SignalAdapter::ReceivePollingJob, type: :job do
  describe '#perform_later' do
    subject { -> { described_class.perform_later } }
    it 'enqueues a job' do
      should have_enqueued_job
    end
  end
  describe '#perform' do
    let(:job) { described_class.new }
    subject { -> { job.perform } }

    describe 'without a phone number' do
      before do
        allow(Setting).to receive(:signal_server_phone_number).and_return(nil)
      end

      it 'stops immediately as there are no messages to receive' do
        should_not raise_error
      end
    end

    describe 'given a phone number', vcr: { cassette_name: :receive_signal_messages } do
      before do
        unless Setting.signal_server_phone_number
          allow(Setting).to receive(:signal_server_phone_number).and_return('SIGNAL_SERVER_PHONE_NUMBER')
        end
      end

      describe 'if an unknown contributor sends us a message' do
        it 'raises an error so that our admins get notified' do
          should raise_error(SignalAdapter::UnknownContributorError)
        end

        it 'does not create messages' do
          expect do
            subject.call
          rescue SignalAdapter::UnknownContributorError
            nil
          end.not_to(change { Message.count })
        end
      end

      describe 'given a request' do
        before { create(:request) }

        it 'does not create messages without a recipient' do
          expect do
            subject.call
          rescue SignalAdapter::UnknownContributorError
            nil
          end.not_to(change { Message.count })
        end

        describe 'and a corresponding contributor' do
          before do
            create(:contributor, signal_phone_number: '+4915112345789')
            create(:contributor, signal_phone_number: '+4915155555555')
          end

          it 'create a message' do
            should(change { Message.count }.from(0).to(1))
          end

          it 'assigns the correct contributor' do
            subject.call
            expect(Message.first.contributor.signal_phone_number).to eq('+4915112345789')
          end
        end
      end
    end

    describe 'if unknown content is included in the message', vcr: { cassette_name: :receive_signal_messages_containing_attachment } do
      let(:contributor) { create(:contributor, signal_phone_number: '+4915112345678') }
      before do
        unless Setting.signal_server_phone_number
          allow(Setting).to receive(:signal_server_phone_number).and_return('SIGNAL_SERVER_PHONE_NUMBER')
        end
        allow(Setting).to receive(:signal_unknown_content_message).and_return('We cannot process this content')
        create(:request)
        contributor
      end

      it 'bounces a warning to the contributor' do
        should have_enqueued_job(SignalAdapter::Outbound).with(
          text: 'We cannot process this content',
          recipient: contributor
        )
      end
    end
  end
end

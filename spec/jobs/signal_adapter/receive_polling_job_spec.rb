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

    describe 'without a registered signal phone number on the server' do
      before do
        allow(Setting).to receive(:signal_server_phone_number).and_return(nil)
      end

      it 'stops immediately as there are no messages to receive' do
        should_not raise_error
      end
    end

    describe 'given a registered signal phone number on the server', vcr: { cassette_name: :receive_signal_messages } do
      before do
        unless Setting.signal_server_phone_number
          allow(Setting).to receive(:signal_server_phone_number).and_return('SIGNAL_SERVER_PHONE_NUMBER')
        end
        allow(Sentry).to receive(:capture_exception).with(an_instance_of(SignalAdapter::UnknownContributorError))
      end

      describe 'if an unknown contributor sends us a message' do
        it { should_not(change { Message.count }) }

        it 'sends an error to Sentry so that our admins get notified' do
          subject.call
          expect(Sentry).to have_received(:capture_exception)
        end
      end

      describe 'given a request' do
        before { create(:request) }

        describe 'and one message from an unknown contributor' do
          it { should_not(change { Message.count }) }
        end

        describe 'and one message from a known contributor' do
          before do
            create(:contributor, signal_phone_number: '+4915112345789')
            create(:contributor, signal_phone_number: '+4915155555555')
          end

          it 'is expected to create a message' do
            should(change { Message.count }.from(0).to(1))
          end

          it 'is expected to assign the correct contributor' do
            subject.call
            expect(Message.first.contributor.signal_phone_number).to eq('+4915112345789')
          end
        end

        describe 'and multiple messages from known and unknown contributors', vcr: { cassette_name: :receive_multiple_signal_messages } do
          before do
            create(:contributor, signal_phone_number: '+4915112345789')
          end

          it 'creates a message for the known contributor' do
            should(change { Message.count }.from(0).to(1))
          end

          it 'raises an error for the unknown contributor so that our admins get notified' do
            subject.call
            expect(Sentry).to have_received(:capture_exception)
          end
        end
      end
    end

    describe 'on a message with attachments' do
      let(:contributor) { create(:contributor, signal_phone_number: '+4915112345678') }
      before do
        unless Setting.signal_server_phone_number
          allow(Setting).to receive(:signal_server_phone_number).and_return('SIGNAL_SERVER_PHONE_NUMBER')
        end
        allow(File).to receive(:open).and_call_original
        allow(File).to receive(:open)
          .with("#{Setting.signal_rest_cli_attachment_path}zuNhdpIHpRU_9Du-B4oG")
          .and_return(file_fixture('signal_message_with_attachment').open)
        create(:request)
        contributor
      end

      describe 'if the attachment included in the message is supported',
               vcr: { cassette_name: :receive_signal_messages_containing_supported_attachment } do
        let(:attached_file) { Message.first.files.first.attachment }
        it 'is expected to save the attachments as attached files' do
          subject.call
          expect(attached_file).to be_attached
        end
      end

      describe 'if the attachment included in the message is not supported',
               vcr: { cassette_name: :receive_signal_messages_containing_unsupported_attachment } do
        before do
          allow(Setting).to receive(:signal_unknown_content_message).and_return('We cannot process this content')
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
end

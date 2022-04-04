# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SignalAdapter::ReceivePollingJob, type: :job do
  describe '#perform_later' do
    subject { -> { described_class.perform_later } }
    let(:queue) { 'poll_signal_messages' }

    it { should have_enqueued_job(described_class).on_queue(queue) }

    context 'given a polling job' do
      # Our implementation is specific to `delayed_job`. During test
      # execution, an in-memory test adapter is used. Thus, we have
      # to set up the job record explicitly.
      let!(:job) { Delayed::Job.create(queue: queue, handler: 'Job', failed_at: failed_at) }
      let(:failed_at) { nil }

      it { should_not have_enqueued_job(described_class).on_queue(queue) }

      context 'that has failed' do
        let(:failed_at) { Time.zone.now }
        it { should have_enqueued_job(described_class).on_queue(queue) }
      end
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
        expect(job).not_to receive(:ping_monitoring_service)
        should_not raise_error
      end
    end

    describe 'given a registered signal phone number on the server', vcr: { cassette_name: :receive_signal_messages } do
      before do
        create(:request)

        unless Setting.signal_server_phone_number
          allow(Setting).to receive(:signal_server_phone_number).and_return('SIGNAL_SERVER_PHONE_NUMBER')
        end

        allow(job).to receive(:ping_monitoring_service).and_return(nil)
      end

      context 'if consuming the message fails' do
        before do
          allow(Sentry).to receive(:capture_exception).with(an_instance_of(StandardError))
          allow_any_instance_of(SignalAdapter::Inbound).to receive(:consume).and_raise(StandardError)
        end

        it 'sends error to Sentry' do
          expect { subject.call }.not_to raise_error
          expect(Sentry).to have_received(:capture_exception)
          expect(job).to have_received(:ping_monitoring_service)
        end
      end

      describe 'given a message from an unknown contributor' do
        before { allow(Sentry).to receive(:capture_exception).with(an_instance_of(SignalAdapter::UnknownContributorError)) }

        it { should_not(change { Message.count }) }

        it 'sends an error to Sentry so that our admins get notified' do
          subject.call
          expect(Sentry).to have_received(:capture_exception)
        end
      end

      describe 'given a message from a contributor with incomplete onboarding' do
        let!(:contributor) { create(:contributor, signal_phone_number: '+4915112345789') }

        before do
          allow(Setting).to receive(:onboarding_success_heading).and_return('Welcome!')
          allow(Setting).to receive(:onboarding_success_text).and_return('')
        end

        it { should_not(change { Message.count }) }

        it 'sends welcome message' do
          should have_enqueued_job(SignalAdapter::Outbound).with do |text, recipient|
            expect(text).to eq("Welcome!\n")
            expect(recipient.id).to eq(contributor.id)
          end
        end

        it 'sets signal_onboarding_completed_at' do
          subject.call
          expect(contributor.reload.signal_onboarding_completed_at).to be_present
        end
      end

      describe 'given a message from a contributor with completed onboarding' do
        before do
          create(:contributor, signal_phone_number: '+4915112345789', signal_onboarding_completed_at: Time.zone.now)
          create(:contributor, signal_phone_number: '+4915155555555', signal_onboarding_completed_at: Time.zone.now)
        end

        it 'is expected to create a message' do
          should(change { Message.count }.from(0).to(1))
        end

        it 'is expected to assign the correct contributor' do
          subject.call
          expect(Message.first.contributor.signal_phone_number).to eq('+4915112345789')
        end
      end

      describe 'given multiple messages from known and unknown contributors', vcr: { cassette_name: :receive_multiple_signal_messages } do
        before do
          allow(Sentry).to receive(:capture_exception).with(an_instance_of(SignalAdapter::UnknownContributorError))
          create(:contributor, signal_phone_number: '+4915112345789', signal_onboarding_completed_at: Time.zone.now)
        end

        it 'creates a message for the known contributor' do
          should(change { Message.count }.from(0).to(1))
        end

        it 'raises an error for the unknown contributor so that our admins get notified' do
          subject.call
          expect(Sentry).to have_received(:capture_exception)
        end
      end

      describe 'given a message with attachments' do
        let!(:contributor) { create(:contributor, signal_phone_number: '+4915112345678', signal_onboarding_completed_at: Time.zone.now) }

        before do
          allow(File).to receive(:open).and_call_original
          allow(File).to receive(:open)
            .with("#{Setting.signal_cli_rest_api_attachment_path}zuNhdpIHpRU_9Du-B4oG")
            .and_return(file_fixture('signal_message_with_attachment').open)
        end

        describe 'that is supported',
                 vcr: { cassette_name: :receive_signal_messages_containing_supported_attachment } do
          let(:attached_file) { Message.first.files.first.attachment }
          it 'is expected to save the attachments as attached files' do
            subject.call
            expect(attached_file).to be_attached
          end
        end

        describe 'that is unsupported',
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
end

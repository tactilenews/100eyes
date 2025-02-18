# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

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
    subject { -> { job.perform } }

    let(:job) { described_class.new }
    let!(:organization) { create(:organization, signal_server_phone_number: signal_server_phone_number) }
    let(:signal_server_phone_number) { '+4912345678' }

    describe 'without a registered signal phone number on the server' do
      let(:signal_server_phone_number) { nil }

      it 'stops immediately as there are no messages to receive' do
        expect(job).not_to receive(:ping_monitoring_service)
        should_not raise_error
      end
    end

    describe 'given a registered signal phone number on the server', vcr: { cassette_name: :receive_signal_messages } do
      let(:user) { create(:user, first_name: 'why', organizations: [organization]) }

      before do
        create(:request, organization: organization, user: user)

        allow(ENV).to receive(:fetch).with('SIGNAL_CLI_REST_API_ENDPOINT', 'http://localhost:8080').and_return('http://localhost:8080')
        allow(job).to receive(:ping_monitoring_service).and_return(nil)
      end

      context 'if consuming the message fails' do
        let!(:contributor) do
          create(:contributor, signal_phone_number: '+4915112345789', signal_onboarding_completed_at: 2.weeks.ago,
                               organization: organization)
        end

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

      describe 'given a message from a contributor for the first time',
               vcr: { cassette_name: :receive_signal_message_to_complete_onboarding } do
        let!(:contributor) { create(:contributor, signal_onboarding_token: signal_onboarding_token, organization: organization) }
        let(:signal_uuid) { 'valid_uuid' }
        let(:signal_onboarding_token) { 'CM1TOEC7' }

        it 'does not create a message' do
          expect { subject.call }.not_to change(Message, :count)
        end

        it 'enqueues a job to create the contact' do
          expect do
            subject.call
          end.to have_enqueued_job(SignalAdapter::CreateContactJob).with(contributor_id: contributor.id)
        end

        it 'enqueues a job to attach contributors avatar' do
          expect { subject.call }.to have_enqueued_job(SignalAdapter::AttachContributorsAvatarJob).with(contributor_id: contributor.id)
        end

        it 'is expected to complete the onboarding' do
          expect { subject.call }.to change { contributor.reload.signal_uuid }.from(nil).to(signal_uuid)
                                                                              .and change {
                                                                                     contributor.reload.signal_onboarding_completed_at
                                                                                   }.from(nil).to(kind_of(ActiveSupport::TimeWithZone))
        end

        it 'sends the welcome message' do
          expect { subject.call }.to have_enqueued_job(SignalAdapter::Outbound::Text).with(
            contributor_id: contributor.id,
            text: [organization.onboarding_success_heading, organization.onboarding_success_text].join("\n")
          )
        end
      end

      describe 'given multiple messages from known and unknown contributors', vcr: { cassette_name: :receive_multiple_signal_messages } do
        before do
          allow(Sentry).to receive(:capture_exception).with(an_instance_of(SignalAdapter::UnknownContributorError))
          create(:contributor, signal_phone_number: '+4915112345789', organization: organization)
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
        let!(:contributor) do
          create(:contributor, signal_phone_number: '+4915112345678', signal_onboarding_completed_at: 2.weeks.ago,
                               organization: organization)
        end

        before do
          allow(ENV).to receive(:fetch).with('SIGNAL_CLI_REST_API_ATTACHMENT_PATH',
                                             'signal-cli-config/attachments/').and_return('signal-cli-config/attachments/')
          allow(File).to receive(:open).and_call_original
          allow(File).to receive(:open)
            .with('signal-cli-config/attachments/zuNhdpIHpRU_9Du-B4oG')
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
            organization.update(signal_unknown_content_message: 'We cannot process this content')
          end

          it 'bounces a warning to the contributor' do
            should have_enqueued_job(SignalAdapter::Outbound::Text).with(
              contributor_id: contributor.id,
              text: 'We cannot process this content'
            )
          end
        end
      end

      describe 'given a delivery receipt', vcr: { cassette_name: :receive_signal_delivery_receipt } do
        # Use signal-ci directly to send out a message to the `signal_uuid` below
        let!(:contributor) do
          create(:contributor, signal_uuid: '4c941782-a59c-4428-a19f-8d7628b6ca42', signal_onboarding_completed_at: 2.weeks.ago,
                               organization: organization)
        end
        let(:request) { create(:request, organization: organization, user: user) }
        let!(:message) { create(:message, :outbound, recipient: contributor, request: request, organization: organization, sender: user) }

        it 'updates message.delivered_at' do
          expect { subject.call }.to change { message.reload.delivered_at }.from(nil).to(Time.zone.at(1_719_664_635))
        end
      end

      describe 'given a known contributor requests to unsubscribe', vcr: { cassette_name: :receive_signal_message_to_unsubscribe } do
        before do
          allow(ENV).to receive(:fetch).with('SIGNAL_CLI_REST_API_ENDPOINT', 'http://localhost:8080').and_return('http://signal:8080')
        end

        let!(:contributor) do
          create(:contributor, signal_phone_number: '+4915112345789', signal_onboarding_completed_at: 2.weeks.ago,
                               organization: organization)
        end
        it { is_expected.to have_enqueued_job(UnsubscribeContributorJob).with(contributor.id, SignalAdapter::Outbound) }
      end

      describe 'given a contributor who has unsubscribed and requests to resubscribe',
               vcr: { cassette_name: :receive_signal_message_to_resubscribe } do
        before do
          allow(ENV).to receive(:fetch).with('SIGNAL_CLI_REST_API_ENDPOINT', 'http://localhost:8080').and_return('http://signal:8080')
        end

        let!(:contributor) do
          create(:contributor, signal_phone_number: '+4915112345789', unsubscribed_at: 1.week.ago,
                               signal_onboarding_completed_at: 2.weeks.ago, organization: organization)
        end

        it {
          is_expected.to have_enqueued_job(ResubscribeContributorJob).with(contributor.id, SignalAdapter::Outbound)
        }
      end

      describe 'given the Signal server is unavailable' do
        let(:error_message) do
          [['error', "Error while checking account #{organization.signal_server_phone_number}: [502] Bad response: 502 \n"]].to_json
        end

        before do
          create(:request, organization: organization)

          allow(job).to receive(:ping_monitoring_service).and_return(nil)
          stub_request(:get, %r{v1/receive}).to_return(status: 400, body: error_message)
        end

        it 'raises an SignalAdapter::ServerError' do
          expect { subject.call }.to raise_error(SignalAdapter::ServerError)
        end

        it 'stops immediately as a server error occurred' do
          subject.call
        rescue SignalAdapter::ServerError
          expect(SignalAdapter::Inbound).not_to receive(:new)
          expect(job).not_to receive(:ping_monitoring_service)
        end
      end
    end
  end
end

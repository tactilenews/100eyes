# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

RSpec.describe SignalAdapter::Api do
  let(:api) { described_class }

  describe '#perform_request' do
    let(:uri) { URI.parse('http://signal:8080/v2/send') }
    let(:request) { Net::HTTP::Post.new(uri) }
    let(:recipient) { create(:contributor) }

    before do
      allow(ErrorNotifier).to receive(:report)
    end

    describe 'http response code' do
      describe '200' do
        before(:each) do
          stub_request(:post, uri).to_return(status: 200)
        end
        specify { expect { |block| api.perform_request(request, recipient, &block) }.to yield_control }

        describe 'ErrorNotifier' do
          subject { ErrorNotifier }
          before { api.perform_request(request, recipient) }
          it { should_not have_received(:report) }
        end
      end

      describe '400' do
        before(:each) do
          stub_request(:post, uri).to_return(status: 400, body: { error: 'Ouch!' }.to_json)
        end

        specify { expect { |block| api.perform_request(request, recipient, &block) }.not_to yield_control }

        describe 'ErrorNotifier' do
          subject { ErrorNotifier }
          before { api.perform_request(request, recipient) }
          it { should have_received(:report) }
        end

        describe 'Unregistered user error' do
          let!(:admin) { create_list(:user, 2, admin: true) }
          let!(:non_admin_user) { create(:user) }

          before do
            stub_request(:post, uri).to_return(status: 400, body: { error: 'Unregistered user' }.to_json)
          end

          subject { -> { api.perform_request(request, recipient) } }

          it 'marks the contributor as inactive' do
            expect { subject.call }.to change { recipient.reload.deactivated_at }.from(nil).to(kind_of(ActiveSupport::TimeWithZone))
          end

          it_behaves_like 'an ActivityNotification', 'ContributorMarkedInactive'

          it 'enqueues a job to inform admin' do
            expect { subject.call }.to have_enqueued_job.on_queue('default').with(
              'PostmarkAdapter::Outbound',
              'contributor_marked_as_inactive_email',
              'deliver_now', # How ActionMailer works in test environment, even though in production we call deliver_later
              {
                params: { admin: an_instance_of(User), contributor: recipient },
                args: []
              }
            ).exactly(2).times
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarkInactiveContributorInactiveJob do
  describe '#perform_later(contributor_id:)' do
    subject { -> { described_class.new.perform(contributor_id: contributor.id) } }

    let!(:admin) { create_list(:user, 2, admin: true) }
    let!(:non_admin_user) { create(:user) }

    context 'given an unknown contributor' do
      let(:contributor) { Contributor.new(id: 12_345) }

      # if a contributor is deleted from the db before the job is run,
      # then we should not try to run the job, but exit early.
      it { is_expected.not_to raise_error(NoMethodError) }
    end

    context 'given a known contributor' do
      let(:contributor) { create(:contributor) }

      it { is_expected.to change { contributor.reload.deactivated_at }.from(nil).to(kind_of(ActiveSupport::TimeWithZone)) }

      it_behaves_like 'an ActivityNotification', 'ContributorMarkedInactive'
      it 'enqueues a job to inform admin' do
        expect { subject.call }.to have_enqueued_job.on_queue('default').with(
          'PostmarkAdapter::Outbound',
          'contributor_marked_as_inactive_email',
          'deliver_now', # How ActionMailer works in test environment, even though in production we call deliver_later
          {
            params: { admin: an_instance_of(User), contributor: contributor },
            args: []
          }
        ).exactly(2).times
      end
    end
  end
end

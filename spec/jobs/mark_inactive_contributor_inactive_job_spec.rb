# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarkInactiveContributorInactiveJob do
  describe '#perform_later(contributor_id:)' do
    subject { -> { described_class.new.perform(contributor_id: contributor.id) } }

    let!(:admin) { create_list(:user, 2, admin: true) }
    let!(:non_admin_user) { create(:user) }

    context 'given a known organization' do
      let(:organization) { create(:organization) }
      let(:contributor) { create(:contributor) }

      context 'given a known contributor' do
        before do
          contributor.update(organization_id: organization.id)
          non_admin_user.update(organizations: [organization])
        end

        it { is_expected.to change { contributor.reload.deactivated_at }.from(nil).to(kind_of(ActiveSupport::TimeWithZone)) }
        it_behaves_like 'an ActivityNotification', 'ContributorMarkedInactive', 3
        it 'enqueues a job to inform admin' do
          expect { subject.call }.to have_enqueued_job.on_queue('default').with(
            'PostmarkAdapter::Outbound',
            'contributor_marked_as_inactive_email',
            'deliver_now', # How ActionMailer works in test environment, even though in production we call deliver_later
            {
              params: { admin: an_instance_of(User), contributor: contributor, organization: organization },
              args: []
            }
          ).exactly(2).times
        end
      end
    end
  end
end

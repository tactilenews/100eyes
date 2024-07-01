# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarkInactiveContributorInactiveJob do
  describe '#perform_later(contributor_id:)' do
    subject { -> { described_class.new.perform(organization_id: organization.id, contributor_id: contributor.id) } }

    let!(:admin) { create_list(:user, 2, admin: true) }
    let!(:non_admin_user) { create(:user) }

    context 'given an unknown organization and unknown contributor' do
      let(:organization) { Organization.new(id: 12_345) }
      let(:contributor) { Contributor.new(id: 12_345) }

      it 'does not throw an error' do
        expect { subject.call }.not_to raise_error
      end

      it 'does not enqueue job' do
        expect { subject.call }.not_to have_enqueued_job
      end
    end

    context 'given a known organization' do
      let(:organization) { create(:organization) }
      let(:contributor) { create(:contributor) }

      context 'given a known contributor' do
        context 'that does not belong to the organization' do
          it { is_expected.not_to raise_error }
        end

        context 'that does belong to the organization' do
          before { contributor.update(organization_id: organization.id) }

          it { is_expected.to change { contributor.reload.deactivated_at }.from(nil).to(kind_of(ActiveSupport::TimeWithZone)) }
          it_behaves_like 'an ActivityNotification', 'ContributorMarkedInactive'
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
end

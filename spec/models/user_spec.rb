# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User do
  let(:organization) { create(:organization, business_plan_name: 'Editorial pro') }
  let!(:users) { create_list(:user, 3, organization: organization) }

  describe '#notify_admin' do
    subject { create(:user, organization: organization) }

    context 'non-admin' do
      it 'does not schedule a job' do
        expect(User.count).to eq(organization.business_plan.number_of_users)
        expect { subject }.not_to have_enqueued_job
      end
    end

    context 'with admin' do
      let!(:admin) { create_list(:user, 3, admin: true) }

      it 'schedules a job to notify only admin of the change' do
        expect(User.admin(false).count).to eq(organization.business_plan.number_of_users)
        expect { subject }.to have_enqueued_job.on_queue('default').with(
          'PostmarkAdapter::Outbound',
          'user_count_exceeds_plan_limit_email',
          'deliver_now', # How ActionMailer works in test environment, even though in production we call deliver_later
          {
            params: { admin: an_instance_of(User), organization: organization },
            args: []
          }
        ).exactly(3).times
      end
    end
  end
end

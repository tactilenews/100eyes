# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User do
  let(:organization) { create(:organization, business_plan_name: 'Editorial pro') }
  let!(:users) { create_list(:user, 3, organizations: [organization]) }

  describe 'validations' do
    describe '#email' do
      it 'must be unique' do
        create(:user, email: 'user@example.org')
        expect { create(:user, email: 'user@example.org') }.to raise_error(ActiveRecord::RecordInvalid)
        expect { create(:user, email: 'USER@example.org') }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  describe '#notify_admin' do
    subject { create(:user, organizations: [organization]) }

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

  describe '#reset_otp' do
    let(:user) { create(:user) }
    subject { user.update(otp_enabled: false) }
    it 'updates `otp_secret_key`' do
      expect { subject }.to change(user, :otp_secret_key)
    end

    context 'updating other attribute' do
      subject { user.update(first_name: 'Keep my secret', last_name: 'Please') }

      it ' does not update otp_secret_key' do
        expect { subject }.not_to change(user, :otp_secret_key)
      end
    end
  end
end

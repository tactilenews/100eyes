# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Organization do
  let(:organization) { create(:organization, business_plan_name: 'Editorial basic') }

  describe '#notify_admin' do
    subject { organization.update(params) }

    context 'does not schedule a PostmarkAdpater::Outbound job' do
      let(:params) { { name: 'SomethingElse', upgrade_discount: 100 } }

      it 'for other updates' do
        expect { subject }.not_to have_enqueued_job
      end
    end

    context 'with admin' do
      let!(:admin) { create_list(:user, 3, admin: true) }
      let!(:users) { create_list(:user, 2) }

      describe 'plan downgraded' do
        let(:params) { { business_plan: create(:business_plan, :editorial_pro), upgraded_business_plan_at: nil } }

        it 'does not schedule a job' do
          expect { subject }.not_to have_enqueued_job.on_queue('default').with(
            'PostmarkAdapter::Outbound',
            'business_plan_upgraded_email',
            'deliver_now', # How ActionMailer works in test environment, even though in production we call deliver_later
            {
              params: { admin: an_instance_of(User), organization: organization, price_per_month_with_discount: anything },
              args: []
            }
          )
        end
      end

      describe 'plan upgraded' do
        let(:params) { { business_plan: create(:business_plan, :editorial_pro), upgraded_business_plan_at: Time.current } }

        it 'schedules a job to notify only admin of the change' do
          expect { subject }.to have_enqueued_job.on_queue('default').with(
            'PostmarkAdapter::Outbound',
            'business_plan_upgraded_email',
            'deliver_now', # How ActionMailer works in test environment, even though in production we call deliver_later
            {
              params: { admin: an_instance_of(User), organization: organization, price_per_month_with_discount: kind_of(String) },
              args: []
            }
          ).exactly(3).times
        end
      end
    end
  end
end

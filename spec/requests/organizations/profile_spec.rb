# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ':organization_id/profile' do
  let!(:user) { create(:user, organizations: [organization]) }
  let(:contact_person) { create(:user) }
  let(:organization) { create(:organization, contact_person: contact_person, business_plan_name: 'Editorial pro') }

  before do
    organization.users << contact_person
    organization.save
  end

  describe 'GET /index' do
    it 'should be successful' do
      get organization_profile_url(organization, as: user)
      expect(response).to be_successful
    end
  end

  describe 'POST /create_user' do
    let(:params) { { user: { first_name: 'Daniel', last_name: 'Theis', email: 'daniel-theis@example.org' } } }

    context 'unauthenticated' do
      subject { -> { post organization_profile_user_path(organization), params: params } }

      it 'does not change user count' do
        expect { subject.call }.not_to(change { User.count })
      end
    end

    context 'authenticated' do
      subject { -> { post organization_profile_user_path(organization, as: user), params: params } }

      it 'creates a user' do
        expect { subject.call }.to(change { User.count }.from(2).to(3))
      end

      it 'redirects to profile page' do
        subject.call
        expect(response).to redirect_to organization_profile_path(organization)
      end

      it 'shows success notification' do
        subject.call
        expect(flash[:success]).not_to be_empty
      end

      describe 'exceeds number of users of plan' do
        let!(:last_user_allocated_by_plan) { create(:user, organizations: [organization]) }
        let!(:admin) { create(:user, admin: true) }

        it 'creates a user' do
          expect(User.admin(false).count).to eq(organization.business_plan.number_of_users)
          expect { subject.call }.to(change { User.admin(false).count }.from(3).to(4))
        end

        it 'redirects to profile page' do
          subject.call
          expect(response).to redirect_to organization_profile_path(organization)
        end

        it 'shows success notification' do
          subject.call
          expect(flash[:success]).not_to be_empty
        end

        it 'schedules a job to notify only admin of the change' do
          expect { subject.call }.to have_enqueued_job.on_queue('default').with(
            'PostmarkAdapter::Outbound',
            'user_count_exceeds_plan_limit_email',
            'deliver_now', # How ActionMailer works in test environment, even though in production we call deliver_later
            {
              params: { admin: admin, organization: organization },
              args: []
            }
          ).exactly(1).times
        end
      end
    end
  end

  describe 'PUT /upgrade_business_plan' do
    let(:business_plan) { create(:business_plan, :editorial_enterprise) }
    let(:params) { { profile: { business_plan_id: business_plan.id } } }

    context 'unauthenticated' do
      subject { -> { put organization_profile_upgrade_business_plan_path(organization), params: params } }

      it 'does not change user count' do
        expect { subject.call }.not_to(change { organization.reload.business_plan })
      end
    end

    context 'authenticated' do
      subject { -> { put organization_profile_upgrade_business_plan_path(organization, as: user), params: params } }

      it 'updates the organization business_plan' do
        current_business_plan = organization.business_plan
        expect { subject.call }.to(change { organization.reload.business_plan }.from(current_business_plan).to(business_plan))
      end

      it 'redirects to profile page' do
        subject.call
        expect(response).to redirect_to organization_profile_path(organization)
      end

      it 'shows success notification' do
        subject.call
        expect(flash[:success]).not_to be_empty
      end

      it 'does not schedule a job for non-admin' do
        expect { subject.call }.not_to have_enqueued_job.on_queue('default').with(
          'PostmarkAdapter::Outbound',
          'business_plan_upgraded_email',
          'deliver_now', # How ActionMailer works in test environment, even though in production we call deliver_later
          {
            params: { admin: an_instance_of(User), organization: organization, price_per_month_with_discount: anything },
            args: []
          }
        )
      end

      context 'schedules PostmarkAdapterJob for admin only' do
        let!(:admin) { create_list(:user, 3, admin: true) }

        it 'schedules a job to notify admin of the change' do
          expect { subject.call }.to have_enqueued_job.on_queue('default').with(
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

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Organization do
  let!(:organization) { create(:organization, business_plan_name: 'Editorial Basic') }

  describe '#notify_admin' do
    subject { organization.update(params) }

    let!(:admin) { create_list(:user, 3, admin: true) }
    let!(:users) { create_list(:user, 2) }

    context 'does not schedule a PostmarkAdpater::Outbound job' do
      let(:params) { { name: 'SomethingElse', upgrade_discount: 100 } }

      it 'for other updates' do
        expect { subject }.not_to have_enqueued_job
      end
    end

    context 'change to business plan' do
      describe 'plan downgraded' do
        let(:params) { { business_plan: create(:business_plan, :editorial_pro), upgraded_business_plan_at: nil } }

        it 'does not schedule a job' do
          expect { subject }.not_to have_enqueued_job
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

  describe '#notify_admin_of_welcome_message_change' do
    subject { organization.update(params) }

    before do
      allow(ENV).to receive(:fetch).with(
        'THREE_SIXTY_DIALOG_PARTNER_REST_API_ENDPOINT', 'https://stoplight.io/mocks/360dialog/360dialog-partner-api/24588693'
      ).and_return('https://stoplight.io/mocks/360dialog/360dialog-partner-api/24588693')
    end

    context 'does not schedule a PostmarkAdpater::Outbound job' do
      let(:params) { { name: 'SomethingElse' } }

      it 'for other updates' do
        expect { subject }.not_to have_enqueued_job
      end
    end

    context 'change to onboarding success heading' do
      let(:params) { { onboarding_success_heading: 'Another message' } }

      it 'schedules a job to create the welcome message, if necessary' do
        expect { subject }.to have_enqueued_job(WhatsAppAdapter::ThreeSixtyDialog::CreateWelcomeMessageTemplateJob).with(
          organization_id: organization.id
        )
      end
    end

    context 'change to onboarding success text' do
      let(:params) { { onboarding_success_text: 'Another message' } }

      it 'schedules a job to create the welcome message, if necessary' do
        expect { subject }.to have_enqueued_job(WhatsAppAdapter::ThreeSixtyDialog::CreateWelcomeMessageTemplateJob).with(
          organization_id: organization.id
        )
      end
    end
  end

  describe '#contributors_tags_with_count' do
    subject { organization.contributors_tags_with_count.pluck(:name, :count) }

    context 'given a contributor with a tag' do
      let!(:contributor) { create(:contributor, tag_list: %w[Homeowner], organization: organization) }
      it { should eq([['Homeowner', 1]]) }

      context 'and a request with the same tag' do
        let!(:request) { create(:request, tag_list: %w[Homeowner], organization: organization) }
        it { should eq([['Homeowner', 1]]) }
      end

      context 'given an inactive contributor with the same tag' do
        before do
          create(:contributor, tag_list: %w[Homeowner], deactivated_at: 1.day.ago, organization: organization)
          create(:contributor, tag_list: 'teacher', unsubscribed_at: 1.day.ago, organization: organization)
        end

        it "does not count inactive contributor's tags" do
          expect(subject).to eq([['Homeowner', 1]])
        end
      end
    end
  end
end

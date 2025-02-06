# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Organization do
  let(:organization) { build(:organization, business_plan_name: 'Editorial Basic') }

  context 'an organization without a name' do
    before { organization.name = nil }

    it 'is expected to be invalid' do
      expect(organization).not_to be_valid
      expect(organization.errors.messages).to eq(name: ['muss ausgefüllt werden'])
    end
  end

  context 'an organization without a project name' do
    before { organization.project_name = nil }

    it 'is expected to be invalid' do
      expect(organization).not_to be_valid
      expect(organization.errors.messages).to eq(project_name: ['muss ausgefüllt werden'])
    end
  end

  context 'given an organization with an existing telegram_bot_username' do
    before do
      create(:organization, telegram_bot_username: 'my_bot')
      organization.telegram_bot_username = 'my_bot'
    end

    it 'is expected to be invalid' do
      expect(organization).not_to be_valid
      expect(organization.errors.messages).to eq(telegram_bot_username: ['ist bereits vergeben'])
    end
  end

  context 'given an organization with a messengers_about_text' do
    before { organization.messengers_about_text = 'Tell us all about your ideas.' }

    it 'is expected to be valid' do
      expect(organization).to be_valid
    end

    context 'greater than 139 characters' do
      before { organization.messengers_about_text = Faker::Lorem.characters(number: 140) }

      it 'is expected to be invalid' do
        expect(organization).not_to be_valid
      end
    end
  end

  describe 'signal_username validations' do
    before { organization.signal_username = nil }

    context 'given signal is not configured' do
      before { organization.signal_server_phone_number = nil }

      it 'is expected to be valid' do
        expect(organization).to be_valid
      end
    end

    context 'given signal is configured, but onboarding has been disallowed' do
      before { organization.onboarding_allowed = { signal: false } }

      it 'is expected to be valid' do
        expect(organization).to be_valid
      end
    end

    context 'given signal is configured and onboarding has not been disallowed' do
      it 'is expected to be invalid' do
        expect(organization).not_to be_valid
        expect(organization.errors.messages[:signal_username]).to include('muss ausgefüllt werden')
      end

      context 'username is less than 3 characters' do
        before { organization.signal_username = 'oh' }

        it 'is expected to be invalid' do
          expect(organization).not_to be_valid
          expect(organization.errors.messages).to eq(signal_username: ['ist zu kurz (weniger als 3 Zeichen)'])
        end
      end

      context 'username is greater than 32 characters' do
        before { organization.signal_username = 'this_is_a_long_username_for_tests' }

        it 'is expected to be invalid' do
          expect(organization).not_to be_valid
          expect(organization.errors.messages).to eq(signal_username: ['ist zu lang (mehr als 32 Zeichen)'])
        end
      end

      context 'username starts with a number' do
        before { organization.signal_username = '100eyes' }

        it 'is expected to be invalid' do
          expect(organization).not_to be_valid
          expect(organization.errors.messages).to eq(signal_username: ['ist nicht gültig'])
        end
      end

      context 'username contains a special character' do
        before { organization.signal_username = 'hundred-eyes' }

        it 'is expected to be invalid' do
          expect(organization).not_to be_valid
          expect(organization.errors.messages).to eq(signal_username: ['ist nicht gültig'])
        end
      end

      context 'username contains capital letter' do
        before { organization.signal_username = 'HundredEyes' }

        it 'is expected to be valid' do
          expect(organization).to be_valid
        end
      end
    end
  end

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
        before { organization.save! }

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
      before { organization.save! }

      let(:params) { { onboarding_success_heading: 'Another message' } }

      it 'schedules a job to create the welcome message, if necessary' do
        expect { subject }.to have_enqueued_job(WhatsAppAdapter::ThreeSixtyDialog::CreateWelcomeMessageTemplateJob).with(
          organization_id: organization.id
        )
      end
    end

    context 'change to onboarding success text' do
      before { organization.save! }

      let(:params) { { onboarding_success_text: 'Another message' } }

      it 'schedules a job to create the welcome message, if necessary' do
        expect { subject }.to have_enqueued_job(WhatsAppAdapter::ThreeSixtyDialog::CreateWelcomeMessageTemplateJob).with(
          organization_id: organization.id
        )
      end
    end
  end

  describe '#update_signal_and_telegram_profiles' do
    context 'given creation of a new organization' do
      subject { organization.save! }

      let(:organization) { build(:organization) }

      it 'it is expected to schedule a job to update the profiles as project_name is required' do
        subject

        expect(SignalAdapter::SetProfileInfoJob).to have_been_enqueued.with(organization_id: organization.id)
        expect(TelegramAdapter::SetProfileInfoJob).to have_been_enqueued.with(organization_id: organization.id)
        expect(WhatsAppAdapter::ThreeSixtyDialog::SetProfileInfoJob).to have_been_enqueued.with(organization_id: organization.id)
      end
    end

    context 'given updating of an existing organization' do
      subject { organization.update(params) }

      before { organization.save! }

      describe 'given an update to an attribute not used in signal or telegram profiles' do
        let(:params) { { name: 'Some other name' } }

        it 'does not schedule either job to update the profiles' do
          expect { subject }.not_to have_enqueued_job(SignalAdapter::SetProfileInfoJob)
          expect { subject }.not_to have_enqueued_job(TelegramAdapter::SetProfileInfoJob)
          expect { subject }.not_to have_enqueued_job(WhatsAppAdapter::ThreeSixtyDialog::SetProfileInfoJob)
        end
      end

      describe 'given an update to the project_name' do
        let(:params) { {  project_name: 'New Project Name' } }

        it 'it is expected to schedule a job to update Signal profile, so it stays in sync' do
          expect { subject }.to have_enqueued_job(SignalAdapter::SetProfileInfoJob).with(organization_id: organization.id)
        end

        it 'it is expected to schedule a job to update Telegram profile, so it stays in sync' do
          expect { subject }.to have_enqueued_job(TelegramAdapter::SetProfileInfoJob).with(organization_id: organization.id)
        end

        it 'it is expected to schedule a job to update WhatsApp profile, so it stays in sync' do
          expect do
            subject
          end.to have_enqueued_job(WhatsAppAdapter::ThreeSixtyDialog::SetProfileInfoJob).with(organization_id: organization.id)
        end
      end

      describe 'given an update to the messengers_about_text' do
        let(:params) { { messengers_about_text: 'About the messenger' } }

        it 'it is expected to schedule a job to update Signal profile, so it stays in sync' do
          expect { subject }.to have_enqueued_job(SignalAdapter::SetProfileInfoJob).with(organization_id: organization.id)
        end

        it 'it is expected to schedule a job to update Telegram profile, so it stays in sync' do
          expect { subject }.to have_enqueued_job(TelegramAdapter::SetProfileInfoJob).with(organization_id: organization.id)
        end

        it 'it is expected to schedule a job to update WhatsApp profile, so it stays in sync' do
          expect do
            subject
          end.to have_enqueued_job(WhatsAppAdapter::ThreeSixtyDialog::SetProfileInfoJob).with(organization_id: organization.id)
        end
      end

      describe 'given an update to the messengers_description_text' do
        let(:params) { { messengers_description_text: 'Description of the messenger' } }

        it 'it is expected not to schedule a job to update Signal profile as it is not used' do
          expect { subject }.not_to have_enqueued_job(SignalAdapter::SetProfileInfoJob)
        end

        it 'it is expected to schedule a job to update Telegram profile, so it stays in sync' do
          expect { subject }.to have_enqueued_job(TelegramAdapter::SetProfileInfoJob).with(organization_id: organization.id)
        end

        it 'it is expected to schedule a job to update WhatsApp profile, so it stays in sync' do
          expect do
            subject
          end.to have_enqueued_job(WhatsAppAdapter::ThreeSixtyDialog::SetProfileInfoJob).with(organization_id: organization.id)
        end
      end
    end
  end

  describe '#contributors_tags_with_count' do
    before { organization.save! }

    subject { organization.contributors_tags_with_count.pluck(:name, :count) }

    it 'makes one database query' do
      expect { subject }.to make_database_queries(count: 1)
    end

    context 'given a contributor with a tag' do
      let!(:contributor) { create(:contributor, tag_list: %w[Homeowner], organization: organization) }
      it { should eq([['Homeowner', 1]]) }

      context 'and a request with the same tag' do
        let!(:request) { create(:request, tag_list: %w[Homeowner], organization: organization) }
        it { should eq([['Homeowner', 1]]) }
      end

      context 'given non-active contributors with the same tag' do
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

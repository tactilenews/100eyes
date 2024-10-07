# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

RSpec.describe WhatsAppAdapter::ThreeSixtyDialog::CreateWelcomeMessageTemplateJob do
  describe '#perform_later(organization_id:)' do
    subject { -> { described_class.new.perform(organization_id: organization.id) } }

    let!(:organization) do
      create(:organization,
             project_name: 'Test Project Name',
             onboarding_success_heading: 'Welcome to Test Project Name',
             three_sixty_dialog_client_waba_account_id: 'valid_waba_account_id')
    end
    let!(:admin) { create_list(:user, 3, admin: true) }
    let!(:users_of_an_organization) { create_list(:user, 2, organizations: [organization]) }
    let!(:user_of_another_organization) { create_list(:user, 2, organizations: [create(:organization)]) }

    before do
      allow(ENV).to receive(:fetch).with(
        'THREE_SIXTY_DIALOG_PARTNER_REST_API_ENDPOINT', 'https://stoplight.io/mocks/360dialog/360dialog-partner-api/24588693'
      ).and_return('https://hub.360dialog.io/api/v2')
      allow(ENV).to receive(:fetch).with(
        'THREE_SIXTY_DIALOG_PARTNER_USERNAME', nil
      ).and_return('valid_partner_username')
      allow(ENV).to receive(:fetch).with(
        'THREE_SIXTY_DIALOG_PARTNER_PASSWORD', nil
      ).and_return('valid_partner_password')
      allow(ENV).to receive(:fetch).with(
        'THREE_SIXTY_DIALOG_PARTNER_ID', nil
      ).and_return('valid_partner_id')
    end

    describe 'ActivityNotifications', vcr: { cassette_name: :three_sixty_dialog_welcome_message_created } do
      it 'creates a notification for all admin and users of an organizaiton' do
        subject.call
        whats_app_template_created_notifications = ActivityNotification.where(type: WhatsAppTemplateCreated.name)
        expect(whats_app_template_created_notifications.count).to eq(5)

        recipient_ids = whats_app_template_created_notifications.pluck(:recipient_id).uniq.sort
        user_ids = users_of_an_organization.pluck(:id).uniq
        admin_ids = admin.pluck(:id)
        all_org_user_plus_admin = (user_ids + admin_ids).sort
        expect(recipient_ids).to eq(all_org_user_plus_admin)
      end
    end
  end
end

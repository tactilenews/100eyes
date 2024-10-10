# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'WhatsApp 360dialog Setup' do
  let(:organization) { create(:organization) }

  describe 'GET /:organization_id/whats_app/setup-successful' do
    subject { -> { get organization_whats_app_setup_successful_url(organization), params: params } }

    let(:params) { { channels: '[valid_channel_id]', client: 'valid_client_id' } }

    it 'updates the organization with the client id' do
      expect { subject.call }.to (change { organization.reload.three_sixty_dialog_client_id }).from(nil).to('valid_client_id')
    end

    it 'schedules a job to create an api key for the client' do
      expect { subject.call }.to have_enqueued_job(WhatsAppAdapter::CreateApiKey).with(
        organization_id: organization.id,
        channel_id: 'valid_channel_id'
      )
    end

    it 'renders the setup success page' do
      subject.call
      expect(response).to be_successful
      expect(page).to have_content('WhatsApp wurde erfolgreich konfiguriert')
      expect(page).to have_content('Du kannst nun mit der Einbindung von WhatsApp-Mitgliedern beginnen.')
    end
  end
end

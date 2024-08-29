# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Errors' do
  let(:user) { create(:user, organizations: [organization]) }
  let(:organization) { create(:organization) }
  let(:organization_not_belonging_to) { create(:organization) }

  before { subject.call }

  describe '404 not found' do
    subject { -> { get organization_dashboard_path(organization_not_belonging_to, as: user) } }

    it 'should return status code' do
      expect(response).to have_http_status(:not_found)
    end

    it 'displays helpful information' do
      expect(page).to have_content('Die Seite, die du suchst, existiert nicht')
      expect(page).to have_content('Vielleicht hast du sich bei der Adresse vertippt oder die Seite ist umgezogen.')
    end
  end

  describe '500 internal server error' do
    subject { -> { patch organization_message_url(organization, message, as: user) } }

    let(:message) { create(:message, creator_id: user.id) }
    before do
      allow_any_instance_of(MessagesController).to receive(:update).and_raise(StandardError)
    end

    it 'should return status code' do
      expect(response).to have_http_status(:internal_server_error)
    end

    it 'displays helpful information' do
      expect(page).to have_content('100eyes hat einen Fehler')
      expect(page).to have_content('Unser Otter Till-E arbeitet gern an einer Lösung, wenn du ihm schreibst support@100eyes')
    end
  end
end

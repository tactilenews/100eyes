# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Scheduling requests', js: true do
  let(:user) { create(:user) }
  let(:organization) { create(:organization) }

  context 'given contributors' do
    before(:each) do
      # `broadcast!` is stubbed in tests
      allow(Request).to receive(:broadcast!).and_call_original
      create(:contributor)
    end

    it 'schedules a future job' do
      visit new_organization_request_path(organization, as: user)

      fill_in 'Titel', with: 'Scheduled request'
      fill_in 'Was möchtest du wissen?', with: 'Did you get my scheduled request?'

      scheduled_datetime = Time.current.tomorrow.beginning_of_hour
      fill_in 'Versand planen. Deine Frage wird automatisch zur eingestellten Zeit verschickt.',
              with: scheduled_datetime.strftime('%Y-%m-%dT%H:%M')
      click_button 'Frage an die Community senden'

      formatted = I18n.l(scheduled_datetime, format: :long)
      success_message = "Ihre Frage wurde erfolgreich geplant, um am #{formatted} an ein Community-Mitglied gesendet zu werden."
      expect(page).to have_current_path(organization_requests_path(organization, filter: :planned))
      expect(page).to have_content('Did you get my scheduled request?')
      expect(page).to have_content(success_message)
    end
  end
end

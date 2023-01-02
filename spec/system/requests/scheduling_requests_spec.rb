# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Scheduling requests', js: true do
  let(:user) { create(:user) }

  context 'given contributors' do
    before(:each) do
      # `broadcast!` is stubbed in tests
      allow(Request).to receive(:broadcast!).and_call_original
      create(:contributor)
    end

    it 'schedules a future job' do
      visit new_request_path(as: user)

      fill_in 'Interner Titel', with: 'Scheduled request'
      fill_in 'Was möchtest du wissen?', with: 'Did you get my scheduled request?'

      scheduled_datetime = Time.current.tomorrow.beginning_of_hour
      fill_in 'Versand planen. Deine Frage wird automatisch zur eingestellten Zeit verschickt.', with: scheduled_datetime
      click_button 'Frage an die Community senden'

      formatted = scheduled_datetime.to_formatted_s(:long)
      success_message = "Ihre Frage wurde erfolgreich geplant, um am #{formatted} an ein Community-Mitglied gesendet zu werden."
      expect(page).to have_content(success_message)
      expect(page).to have_content('Did you get my scheduled request?')
      expect(page).to have_current_path(request_path(Request.first))
    end
  end
end

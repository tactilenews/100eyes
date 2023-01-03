# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Editing requests', js: true do
  let(:user) { create(:user) }
  let(:sent_request) { create(:request) }
  let(:request_scheduled_within_an_hour) { create(:request, schedule_send_for: 59.minutes.from_now) }
  let(:request_scheduled_more_than_an_hour_from_now) { create(:request, schedule_send_for: 90.minutes.from_now) }

  before(:each) do
    # `broadcast!` is stubbed in tests
    allow(Request).to receive(:broadcast!).and_call_original
    create(:contributor)
  end

  it 'conditionally allows editing' do
    # Sent request
    visit edit_request_path(sent_request, as: user)
    expect(page).to have_content('Sie können eine bereits verschickte Frage nicht mehr bearbeiten.')
    expect(page).to have_current_path(requests_path)

    visit edit_request_path(request_scheduled_within_an_hour, as: user)
    expect(page).to have_content('Sie können eine bereits verschickte Frage nicht mehr bearbeiten.')
    expect(page).to have_current_path(requests_path)

    visit edit_request_path(request_scheduled_more_than_an_hour_from_now, as: user)

    expect(page).to have_field('Interner Titel', with: request_scheduled_more_than_an_hour_from_now.title)
    expect(page).to have_field('Was möchtest du wissen?', with: request_scheduled_more_than_an_hour_from_now.text)
    expect(page).to have_field('Versand planen. Deine Frage wird automatisch zur eingestellten Zeit verschickt.',
                               with: request_scheduled_more_than_an_hour_from_now.schedule_send_for.strftime('%Y-%m-%dT%H:%M'))

    fill_in 'Interner Titel', with: '[Edited] Scheduled request'
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

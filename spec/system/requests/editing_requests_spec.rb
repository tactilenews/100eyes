# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Editing requests' do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organizations: [organization]) }
  let(:sent_request) { create(:request, organization: organization) }
  let(:request_scheduled_in_future) { create(:request, schedule_send_for: 2.minutes.from_now, organization: organization) }

  before(:each) do
    create(:contributor, organization: organization)
  end

  it 'conditionally allows editing' do
    # Sent request
    visit edit_organization_request_path(organization, sent_request, as: user)
    expect(page).to have_content('Sie können eine bereits verschickte Frage nicht mehr bearbeiten.')
    expect(page).to have_current_path(organization_requests_path(organization))

    visit edit_organization_request_path(organization, request_scheduled_in_future, as: user)

    expect(page).to have_field('Titel', with: request_scheduled_in_future.title)
    expect(page).to have_field('Was möchtest du wissen?', with: request_scheduled_in_future.text)
    expect(page).to have_field('Versand planen. Deine Frage wird automatisch zur eingestellten Zeit verschickt.',
                               with: request_scheduled_in_future.schedule_send_for.strftime('%Y-%m-%dT%H:%M'))

    fill_in 'Titel', with: '[Edited] Scheduled request'
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

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Deleting requests' do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let!(:broadcasted_request) { create(:request, organization: organization, user: user) }
  let!(:planned_request) { create(:request, schedule_send_for: 1.hour.from_now, organization: organization, user: user) }
  let!(:another_planned_request) { create(:request, schedule_send_for: 5.minutes.from_now, organization: organization, user: user) }

  before do
    allow(Request).to receive(:broadcast!).and_call_original
    create(:contributor, organization: organization)
  end

  it 'conditonally allows deleting' do
    # Broadcasted request

    visit requests_path(as: user)
    within("#request-#{broadcasted_request.id}") do
      expect(page).to have_link(href: request_path(broadcasted_request))
      expect(page).not_to have_link(href: edit_request_path(broadcasted_request))

      find_link(href: request_path(broadcasted_request)).click
    end

    expect(page).to have_current_path(request_path(broadcasted_request))
    visit edit_request_path(broadcasted_request, as: user)
    expect(page).to have_content('Sie können eine bereits verschickte Frage nicht mehr bearbeiten.')
    expect(page).to have_current_path(requests_path)

    # Planned request

    visit requests_path(as: user, filter: :planned)
    within("#request-#{planned_request.id}") do
      find_link(href: edit_request_path(planned_request)).click
    end

    expect(page).to have_current_path(edit_request_path(planned_request))

    click_on I18n.t('components.request_form.planned_request.destroy.button_text')
    expect(page).to have_content(I18n.t('components.destroy_planned_request_modal.heading', request_title: planned_request.title))
    click_on 'löschen'

    expect(page).to have_current_path(requests_path(filter: :planned))
    expect(page).to have_content(I18n.t('request.destroy.successful', request_title: planned_request.title))

    # Planned request, that was then sent out

    visit requests_path(as: user, filter: :planned)
    within("#request-#{another_planned_request.id}") do
      find_link(href: edit_request_path(another_planned_request)).click
    end

    expect(page).to have_current_path(edit_request_path(another_planned_request))
    Timecop.travel(10.minutes.from_now)
    another_planned_request.update(broadcasted_at: 5.minutes.ago)
    click_on I18n.t('components.request_form.planned_request.destroy.button_text')
    expect(page).to have_content(I18n.t('components.request_form.planned_request.destroy.button_text',
                                        request_title: another_planned_request.title))
    click_on 'löschen'

    expect(page).to have_current_path(requests_path)
    expect(page).to have_content(I18n.t('request.destroy.broadcasted_request_unallowed', request_title: another_planned_request.title))
  end
end

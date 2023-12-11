# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Deleting requests' do
  let(:user) { create(:user) }
  let!(:broadcasted_request) { create(:request) }
  let!(:planned_request) { create(:request, schedule_send_for: 1.hour.from_now) }

  before do
    allow(Request).to receive(:broadcast!).and_call_original
    create(:contributor)
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
    page.accept_confirm(I18n.t('request.destroy_confirm', request_title: planned_request.title)) do
      click_on I18n.t('components.request_form.planned_request.destroy')
    end
    expect(page).to have_content(I18n.t('request.destroy', request_title: planned_request.title))
    expect(page).to have_current_path(requests_path(filter: :planned))
  end
end

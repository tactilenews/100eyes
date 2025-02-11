# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard' do
  let(:organization) { create(:organization) }
  let(:email) { Faker::Internet.email }
  let(:password) { Faker::Internet.password(min_length: 8, max_length: 128) }
  let(:otp_enabled) { true }
  let(:organization) { create(:organization) }
  let(:user) do
    create(:user, first_name: 'Dennis', last_name: 'Schroeder', email: email, password: password, otp_enabled: otp_enabled,
                  organizations: [organization])
  end
  let(:contributor) { create(:contributor, organization: organization) }

  before do
    request = create(:request, user: user, organization: organization)
    create_list(:message, 2, request: request, sender: contributor, organization: organization)
  end

  after { Timecop.return }

  it 'Shows several useful sections' do
    Timecop.travel(Time.current.beginning_of_day + 5.hours)
    visit organization_dashboard_path(organization, as: user)

    expect(page).to have_text('Guten Morgen, Dennis!')
    expect(page).to have_link('Neue Frage stellen', href: new_organization_request_path(organization))

    # ActivityNotifications section
    expect(page).to have_css('section.ActivityNotifications')

    # CommunityMetrics section
    expect(page).to have_css('section.CommunityMetrics')
    within('section.CommunityMetrics') do
      # should never exceed 100%, even if more messages than contributors have been received.
      expect(page).to have_content('100% Interaktionsquote')
    end

    # DayAndTimeActivityHeatmap section
    expect(page).to have_css('section.DayAndTimeActivityHeatmap')

    # DayActivityLinechart section
    expect(page).to have_css('section.DayActivityLinechart')
  end
end

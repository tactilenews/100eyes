# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard' do
  let(:email) { Faker::Internet.safe_email }
  let(:password) { Faker::Internet.password(min_length: 8, max_length: 128) }
  let(:otp_enabled) { true }
  let(:user) { create(:user, first_name: 'Dennis', last_name: 'Schroeder', email: email, password: password, otp_enabled: otp_enabled) }

  it 'Shows several useful sections' do
    Timecop.travel(Time.current.beginning_of_day + 5.hours)
    visit dashboard_path(as: user)

    expect(page).to have_text('Guten Morgen, Dennis!')
    expect(page).to have_link('Neue Frage stellen', href: new_request_path)

    # ActivityNotifications section
    expect(page).to have_css('section.ActivityNotifications')

    # CommunityMetrics section
    expect(page).to have_css('section.CommunityMetrics')
  end
end

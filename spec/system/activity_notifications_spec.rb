# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Activity Notifications' do
  context 'with recent activity' do
    let(:email) { Faker::Internet.safe_email }
    let(:password) { Faker::Internet.password(min_length: 8, max_length: 128) }
    let(:otp_enabled) { true }
    let(:user) { create(:user, email: email, password: password, otp_enabled: otp_enabled) }
    let(:contributor) { create(:contributor) }
    let!(:activity_notification) do
      create(:activity_notification,
             recipient: user,
             type: OnboardingCompleted.name,
             params: { contributor: contributor })
    end

    it 'displays the activity notification on dashboard' do
      visit dashboard_path(as: user)
      expect(page).to have_text('Letzte Aktivität')
      expect(page).to have_text(
        "#{contributor.name} hat sich via #{contributor.channels.first.to_s.capitalize} angemeldet."
      )
    end
  end
end

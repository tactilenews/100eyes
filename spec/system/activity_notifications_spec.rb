# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Activity Notifications' do
  context 'with recent activity' do
    let(:email) { Faker::Internet.safe_email }
    let(:password) { Faker::Internet.password(min_length: 8, max_length: 128) }
    let(:otp_enabled) { true }
    let!(:user) { create(:user, email: email, password: password, otp_enabled: otp_enabled) }
    let(:request) { create(:request) }

    it 'displays the activity notification on dashboard' do
      visit dashboard_path(as: user)

      expect(page).to have_text('Letzte Aktivität')

      # Empty State
      expect(page).to have_text('Sie haben im Moment keine Benachrichtigungen. Bitte senden Sie uns Links zum Onboarding.')

      # OnboardingCompleted
      Timecop.travel(Time.current - 1.minute)
      contributor = create(:contributor)
      Timecop.return

      visit dashboard_path(as: user)
      expect(page).to have_text(
        "#{contributor.name} hat sich via #{contributor.channels.first.to_s.capitalize} angemeldet."
      )
      expect(page).to have_text('vor eine Minute')
      expect(page).to have_link('Zum Profil', href: contributor_path(contributor))

      # MessageReceived
      Timecop.travel(Time.current - 5.hours)
      reply = create(:message, :with_sender, request: request, sender: contributor)
      Timecop.return

      visit dashboard_path(as: user)
      expect(page).to have_text(
        "#{contributor.name} hat auf deine Frage '#{reply.request.title}' beantwortet."
      )
      expect(page).to have_text('vor etwa 5 Stunden')
      expect(page).to have_link('Zur Frage', href: request_path(reply.request))
    end
  end
end

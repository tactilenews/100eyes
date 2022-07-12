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
      contributor = create(:contributor)

      visit dashboard_path(as: user)
      expect(page).to have_text(
        "#{contributor.name} hat sich via #{contributor.channels.first.to_s.capitalize} angemeldet."
      )

      # MessageReceived
      reply = create(:message, :with_sender, request: request, sender: contributor)

      visit dashboard_path(as: user)
      expect(page).to have_text(
        "#{contributor.name} hat auf deine Frage '#{reply.request.title}' beantwortet."
      )

      # I shouldn't be grouped
      contributor_two = create(:contributor, first_name: 'Timmy', last_name: 'Timmerson')

      visit dashboard_path(as: user)
      expect(page).to have_text(
        "#{contributor.name} hat sich via #{contributor.channels.first.to_s.capitalize} angemeldet."
      )

      # I should be grouped
      reply_two = create(:message, :with_sender, request: request, sender: contributor_two)

      visit dashboard_path(as: user)
      expect(page).to have_text(
        "#{contributor_two.name} und 2 andere haben auf deine Frage '#{reply_two.request.title}' beantwortet."
      )
    end
  end
end

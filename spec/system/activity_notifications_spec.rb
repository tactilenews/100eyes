# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Activity Notifications' do
  context 'with recent activity' do
    let(:email) { Faker::Internet.safe_email }
    let(:password) { Faker::Internet.password(min_length: 8, max_length: 128) }
    let(:otp_enabled) { true }
    let!(:user) { create(:user, email: email, password: password, otp_enabled: otp_enabled) }
    let(:request) { create(:request) }
    let(:contributor_without_avatar) { create(:contributor) }

    it 'displays the activity notification on dashboard' do
      visit dashboard_path(as: user)

      expect(page).to have_text('Letzte Aktivität')

      # Empty State
      expect(page).to have_text('Sie haben im Moment keine Benachrichtigungen. Bitte senden Sie uns Links zum Onboarding.')

      # OnboardingCompleted
      Timecop.travel(Time.current - 1.minute)
      contributor = create(:contributor, :with_an_avatar)
      Timecop.return

      visit dashboard_path(as: user)
      expect(page).to have_css("img[src*='example-image.png']")
      expect(page).to have_text(
        "#{contributor.name} hat sich via #{contributor.channels.first.to_s.capitalize} angemeldet."
      )
      expect(page).to have_text('vor eine Minute')
      expect(page).to have_link('Zum Profil', href: contributor_path(contributor))

      # I shouldn't be grouped
      contributor_two = create(:contributor, first_name: 'Timmy', last_name: 'Timmerson')

      visit dashboard_path(as: user)
      expect(page).to have_css('svg.Avatar-initials')
      expect(page).to have_text(
        "#{contributor_two.name} hat sich via #{contributor_two.channels.first.to_s.capitalize} angemeldet."
      )
      expect(page).to have_text('vor weniger als eine Minute')
      expect(page).to have_link('Zum Profil', href: contributor_path(contributor_two))

      # MessageReceived
      Timecop.travel(Time.current - 5.hours)
      reply = create(:message, :with_sender, request: request, sender: contributor_without_avatar)
      Timecop.return

      visit dashboard_path(as: user)
      expect(page).to have_css('svg.Avatar-initials')
      expect(page).to have_text(
        "#{contributor_without_avatar.name} hat auf deine Frage '#{reply.request.title}' beantwortet."
      )
      expect(page).to have_text('vor etwa 5 Stunden')
      expect(page).to have_link('Zur Frage', href: request_path(reply.request))

      # I should be grouped
      reply_two = create(:message, :with_sender, request: request, sender: contributor_two)

      visit dashboard_path(as: user)
      expect(page).to have_text(
        "#{contributor_two.name} und 2 andere haben auf deine Frage '#{reply_two.request.title}' beantwortet."
      )
      expect(page).to have_text('vor weniger als eine Minute')
      expect(page).to have_link('Zur Frage', href: request_path(reply.request))

      # Limit ActivityNotifications to 20
      create_list(:contributor, 21)

      visit dashboard_path(as: user)
      expect(page).to have_text('hat sich via Email angemeldet.', count: 20)
    end
  end
end

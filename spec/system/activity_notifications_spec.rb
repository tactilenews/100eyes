# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Activity Notifications' do
  context 'with recent activity' do
    let(:email) { Faker::Internet.safe_email }
    let(:password) { Faker::Internet.password(min_length: 8, max_length: 128) }
    let(:otp_enabled) { true }
    let!(:user) { create(:user, first_name: 'Johnny', last_name: 'Appleseed', email: email, password: password, otp_enabled: otp_enabled) }
    let(:request) { create(:request) }
    let(:contributor_without_avatar) { create(:contributor) }

    it 'displays the activity notifications on dashboard' do
      visit dashboard_path(as: user)

      expect(page).to have_text('Letzte Aktivität')

      # Empty State
      expect(page).to have_text('Du hast im Moment keine neuen Benachrichtigungen.')

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
      Timecop.travel(Time.current - 1.day)
      reply = create(:message, :with_sender, text: "I'm a reply to #{request.title}", request: request, sender: contributor_without_avatar)
      Timecop.return

      visit dashboard_path(as: user)
      expect(page).to have_css('svg.Avatar-initials')
      expect(page).to have_text(
        "#{contributor_without_avatar.name} hat auf die Frage „#{reply.request.title}” geantwortet."
      )
      expect(page).to have_text('vor einem Tag')
      expect(page).to have_link('Zur Antwort', href: request_path(reply.request, anchor: "message-#{reply.id}"))

      # ChatMessageSent
      click_link 'Zur Antwort'
      expect(page).to have_text("I'm a reply to #{reply.request.title}")
      click_link 'nachfragen'
      expect(page).to have_text('Nachrichtenverlauf')
      fill_in 'message[text]', with: "Thanks for your reply #{contributor_without_avatar.name}!"
      click_button 'Absenden'

      Timecop.travel(Time.current + 5.hours)

      visit dashboard_path(as: user)
      expect(page).to have_text(
        "#{user.name} hat #{contributor_without_avatar.name} geantwortet auf „#{reply.request.title}”."
      )
      expect(page).to have_text('vor etwa 5 Stunden')
      expect(page).to have_link(
        'Zur Chat-Nachricht',
        href: contributor_request_path(contributor_without_avatar, reply.request, anchor: "message-#{Message.first.id}")
      )

      # I should be grouped
      reply_two = create(:message, :with_sender, request: request, sender: contributor_two)

      visit dashboard_path(as: user)
      expect(page).to have_text(
        "#{contributor_two.name} und 1 andere haben auf die Frage „#{reply_two.request.title}” geantwortet."
      )
      expect(page).to have_text('vor weniger als eine Minute')
      expect(page).to have_link('Zur Antwort', href: request_path(reply_two.request, anchor: "message-#{reply_two.id}"))
    end
  end
end

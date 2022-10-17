# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Activity Notifications' do
  context 'with recent activity' do
    let(:email) { Faker::Internet.safe_email }
    let(:coworker_email) { Faker::Internet.safe_email }
    let(:password) { Faker::Internet.password(min_length: 8, max_length: 128) }
    let(:otp_enabled) { true }
    let(:user) { create(:user, first_name: 'Johnny', last_name: 'Appleseed', email: email, password: password, otp_enabled: otp_enabled) }
    let!(:coworker) do
      create(:user, first_name: 'Coworker', last_name: 'Extraordinaire', email: coworker_email, password: password,
                    otp_enabled: otp_enabled)
    end
    let(:request) { create(:request) }
    let(:contributor_without_avatar) { create(:contributor) }
    let(:another_contributor) { create(:contributor) }

    it 'displays the activity notifications on dashboard' do
      visit dashboard_path(as: user)

      expect(page).to have_text('Letzte Aktivität')

      # Empty State
      expect(page).to have_text('Du hast im Moment keine neuen Benachrichtigungen.')

      # OnboardingCompleted
      contributor = create(:contributor, :with_an_avatar)

      Timecop.travel(Time.current + 1.minute)
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
      reply = create(:message, :inbound, text: "I'm a reply to #{request.title}", request: request, sender: contributor_without_avatar)

      Timecop.travel(Time.current + 1.day)
      visit dashboard_path(as: user)

      expect(page).to have_css('svg.Avatar-initials')
      expect(page).to have_text(
        "#{contributor_without_avatar.name} hat auf die Frage „#{request.title}” geantwortet."
      )
      expect(page).to have_text('vor einem Tag')
      expect(page).to have_link('Zur Antwort', href: request_path(request, anchor: "message-#{reply.id}"))

      # ChatMessageSent
      click_link('Zur Antwort', href: request_path(request, anchor: "message-#{reply.id}"))
      expect(page).to have_text("I'm a reply to #{request.title}")
      find("a[href='#{contributor_request_path(contributor_without_avatar, request)}']", text: 'nachfragen').trigger('click')

      expect(page).to have_text('Nachrichtenverlauf')
      fill_in 'message[text]', with: "Thanks for your reply #{contributor_without_avatar.name}!"
      click_button 'Absenden'

      expect(page).to have_current_path(contributor_request_path(contributor_without_avatar, request))
      expect(page).to have_text("Nachricht an #{contributor_without_avatar.name} wurde verschickt")
      expect(page).to have_text("Thanks for your reply #{contributor_without_avatar.name}!")

      Timecop.travel(Time.current + 5.hours)
      visit dashboard_path(as: user)

      expect(page).to have_text(
        "Du hast #{contributor_without_avatar.name} auf „#{request.title}” geantwortet."
      )
      expect(page).to have_text('vor etwa 5 Stunden')
      expect(page).to have_link(
        'Zur Nachricht',
        href: request_path(request, anchor: "message-#{Message.first.id}")
      )

      visit dashboard_path(as: coworker)
      expect(page).to have_text(
        "#{user.name} hat #{contributor_without_avatar.name} auf „#{request.title}” geantwortet."
      )

      # I should be grouped
      reply_two = create(:message, :inbound, request: request, sender: contributor_two,
                                             text: "I'm a reply from #{contributor_two.name}")

      visit dashboard_path(as: user)
      expect(page).to have_text(
        "#{contributor_two.name} und #{contributor_without_avatar.name} haben auf die Frage „#{request.title}” geantwortet."
      )
      expect(page).to have_text('vor weniger als eine Minute')
      expect(page).to have_link('Zur Antwort', href: request_path(request, anchor: "message-#{reply_two.id}"))

      reply_by_same_contributor = create(:message, :inbound, request: request, sender: contributor_two,
                                                             text: "I'm a reply from the same contributor: #{contributor_two.name}")

      visit dashboard_path(as: user)
      expect(page).to have_text(
        "#{contributor_two.name} und #{contributor_without_avatar.name} haben auf die Frage „#{request.title}” geantwortet."
      )
      expect(page).to have_link('Zur Antwort',
                                href: request_path(request, anchor: "message-#{reply_by_same_contributor.id}"))

      click_link('Zur Antwort', href: request_path(request, anchor: "message-#{reply_by_same_contributor.id}"))
      expect(page).to have_text("I'm a reply from the same contributor: #{contributor_two.name}")
      find("a[href='#{contributor_request_path(contributor_two, request)}']", text: 'nachfragen').trigger('click')

      expect(page).to have_text('Nachrichtenverlauf')
      fill_in 'message[text]', with: "Thanks for your reply #{contributor_two.name}!"
      click_button 'Absenden'

      expect(page).to have_current_path(contributor_request_path(contributor_two, request))
      expect(page).to have_text("Nachricht an #{contributor_two.name} wurde verschickt")
      expect(page).to have_text("Thanks for your reply #{contributor_two.name}!")

      Timecop.travel(Time.current + 1.week)
      visit dashboard_path(as: user)

      expect(page).to have_text(
        "Du hast #{contributor_two.name} und #{contributor_without_avatar.name} auf die Frage „#{request.title}” geantwortet."
      )
      expect(page).to have_text('vor 7 Tage')
      expect(page).to have_link(
        'Zur Nachricht',
        href: request_path(request, anchor: "message-#{Message.first.id}")
      )

      click_link('Zur Antwort', href: request_path(request, anchor: "message-#{reply_by_same_contributor.id}"))
      expect(page).to have_text("I'm a reply from #{contributor_two.name}")
      find("a[href='#{contributor_request_path(contributor_two, request)}']", text: 'nachfragen').trigger('click')

      expect(page).to have_text('Nachrichtenverlauf')
      fill_in 'message[text]', with: "This is another chat message to #{contributor_two.name}, but it doesn't count in the dashboard!"
      click_button 'Absenden'

      expect(page).to have_current_path(contributor_request_path(contributor_two, request))
      expect(page).to have_text("Nachricht an #{contributor_two.name} wurde verschickt")

      expect(page).to have_text("This is another chat message to #{contributor_two.name}, but it doesn't count in the dashboard!")

      visit dashboard_path(as: user)

      expect(page).to have_text(
        "Du hast #{contributor_two.name} und #{contributor_without_avatar.name} auf die Frage „#{request.title}” geantwortet."
      )
      expect(page).to have_link(
        'Zur Nachricht',
        href: request_path(request, anchor: "message-#{Message.first.id}")
      )

      visit dashboard_path(as: coworker)
      expect(page).to have_text(
        "#{user.name} hat #{contributor_two.name} und #{contributor_without_avatar.name} auf die Frage „#{request.title}” geantwortet."
      )

      click_link('Zur Antwort', href: request_path(request, anchor: "message-#{reply_by_same_contributor.id}"))
      expect(page).to have_text("I'm a reply from #{contributor_two.name}")
      find("a[href='#{contributor_request_path(contributor_two, request)}']", text: 'nachfragen').trigger('click')

      expect(page).to have_text('Nachrichtenverlauf')
      fill_in 'message[text]', with: "This is a chat message from #{coworker.name} to #{contributor_two.name}"
      click_button 'Absenden'

      expect(page).to have_current_path(contributor_request_path(contributor_two, request))
      expect(page).to have_text("Nachricht an #{contributor_two.name} wurde verschickt")

      Timecop.travel(Time.current + 5.minutes)
      expect(page).to have_text("This is a chat message from #{coworker.name} to #{contributor_two.name}")

      visit dashboard_path(as: user)
      expect(page).to have_text(
        "#{coworker.name} hat #{contributor_two.name} auf „#{request.title}” geantwortet."
      )

      create(:message, :inbound, request: request, sender: another_contributor)
      visit dashboard_path(as: user)
      expect(page).to have_text(
        "#{another_contributor.name} und 2 andere haben auf die Frage „#{request.title}” geantwortet."
      )

      Timecop.travel(Time.current + 4.weeks)
      visit dashboard_path(as: user)

      # Empty State
      expect(page).to have_text('Du hast im Moment keine neuen Benachrichtigungen.')
    end
  end
end

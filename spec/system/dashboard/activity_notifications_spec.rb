# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Activity Notifications' do
  context 'with recent activity' do
    let(:organization) { create(:organization) }
    let(:email) { Faker::Internet.email }
    let(:coworker_email) { Faker::Internet.email }
    let(:password) { Faker::Internet.password(min_length: 8, max_length: 128) }
    let(:otp_enabled) { true }
    let(:user) do
      create(:user, first_name: 'Johnny', last_name: 'Appleseed', email: email, password: password, otp_enabled: otp_enabled,
                    organizations: [organization])
    end
    let!(:coworker) do
      create(:user, first_name: 'Coworker', last_name: 'Extraordinaire', email: coworker_email, password: password,
                    otp_enabled: otp_enabled, organizations: [organization])
    end
    let(:request) { create(:request, user: user, organization: organization) }
    let(:contributor_without_avatar) { create(:contributor, organization: organization) }
    let(:another_contributor) { create(:contributor) }

    before { organization.update(users: [user, coworker]) }
    after { Timecop.return }

    it 'displays the activity notifications on dashboard' do
      visit organization_dashboard_path(organization, as: user)

      expect(page).to have_text('Letzte Aktivität')

      # Empty State
      expect(page).to have_text('Du hast im Moment keine neuen Benachrichtigungen.')

      # OnboardingCompleted
      contributor = create(:contributor, :with_an_avatar, organization: organization)

      Timecop.travel(1.minute.from_now)
      visit organization_dashboard_path(organization, as: user)

      expect(page).to have_css("img[src*='example-image.png']")
      expect(page).to have_text(
        "#{contributor.name} hat sich via #{contributor.channels.first.to_s.capitalize} angemeldet."
      )
      expect(page).to have_text('vor eine Minute')
      expect(page).to have_link('Zum Profil', href: organization_contributor_path(organization, contributor))

      # I shouldn't be grouped
      contributor_two = create(:contributor, first_name: 'Timmy', last_name: 'Timmerson', organization: organization)

      visit organization_dashboard_path(organization, as: user)
      expect(page).to have_text(
        "#{contributor_two.name} hat sich via #{contributor_two.channels.first.to_s.capitalize} angemeldet."
      )
      expect(page).to have_text('vor weniger als eine Minute')
      expect(page).to have_link('Zum Profil', href: organization_contributor_path(organization, contributor_two))
      expect(page).to have_css('svg.Avatar-initials')

      # MessageReceived
      reply = create(:message, :inbound, text: "I'm a reply to #{request.title}", request: request, sender: contributor_without_avatar,
                                         organization: organization)

      reply_without_request = create(:message, text: 'Answer to welcome message, or unrelated to request', request: nil,
                                               sender: contributor_without_avatar, organization: organization)

      Timecop.travel(1.day.from_now)
      visit organization_dashboard_path(organization, as: user)

      expect(page).to have_text(
        "#{contributor_without_avatar.name} hat auf die Frage „#{request.title}” geantwortet."
      )
      expect(page).to have_text('vor einem Tag')
      expect(page).to have_link('Zur Antwort',
                                href: organization_request_path(request.organization_id, request, anchor: "message-#{reply.id}"))
      expect(page).to have_css('svg.Avatar-initials')

      expect(page).to have_text(
        "#{contributor_without_avatar.name} hat geantwortet."
      )
      expect(page).to have_text('vor einem Tag')
      expect(page).to have_link('Zur Antwort',
                                href: conversations_organization_contributor_path(reply_without_request.organization_id,
                                                                                  contributor_without_avatar.id,
                                                                                  anchor: "message-#{reply_without_request.id}"))
      expect(page).to have_css('svg.Avatar-initials')

      # ChatMessageSent
      click_link('Zur Antwort', href: organization_request_path(request.organization_id, request, anchor: "message-#{reply.id}"))
      expect(page).to have_text("I'm a reply to #{request.title}")
      find('p', text: "I'm a reply to #{request.title}").hover
      reply_path = conversations_organization_contributor_path(organization, id: contributor_without_avatar, reply_to: reply.id,
                                                                             anchor: 'chat-form')
      expect(page).to have_selector("a[href='#{reply_path}']")
      find("a[href='#{reply_path}']", text: 'antworten').trigger('click')

      expect(page).to have_text("Deine Unterhaltung mit #{contributor_without_avatar.name}")
      fill_in 'message[text]', with: "Thanks for your reply #{contributor_without_avatar.name}!"
      click_button 'Absenden'

      expect(page).to have_current_path(conversations_organization_contributor_path(organization, contributor_without_avatar))
      expect(page).to have_text("Nachricht an #{contributor_without_avatar.name} wurde verschickt")
      expect(page).to have_text("Thanks for your reply #{contributor_without_avatar.name}!")

      Timecop.travel(5.hours.from_now)
      visit organization_dashboard_path(organization, as: user)

      expect(page).to have_text(
        "Du hast #{contributor_without_avatar.name} auf „#{request.title}” geantwortet."
      )
      expect(page).to have_text('vor etwa 5 Stunden')
      expect(page).to have_link(
        'Zur Nachricht',
        href: organization_request_path(request.organization_id, request, anchor: "message-#{Message.first.id}")
      )

      visit organization_dashboard_path(organization, as: coworker)
      expect(page).to have_text(
        "#{user.name} hat #{contributor_without_avatar.name} auf „#{request.title}” geantwortet."
      )

      # I should be grouped
      reply_two = create(:message, :inbound, request: request, sender: contributor_two,
                                             text: "I'm a reply from #{contributor_two.name}", organization: organization)
      visit organization_dashboard_path(organization, as: user)
      expect(page).to have_text(
        "#{contributor_two.name} und #{contributor_without_avatar.name} haben auf die Frage „#{request.title}” geantwortet."
      )
      expect(page).to have_text('vor weniger als eine Minute')
      expect(page).to have_link('Zur Antwort',
                                href: organization_request_path(request.organization_id, request, anchor: "message-#{reply_two.id}"))

      reply_by_same_contributor = create(:message, :inbound, request: request, sender: contributor_two,
                                                             text: "I'm a reply from the same contributor: #{contributor_two.name}",
                                                             organization: organization)

      visit organization_dashboard_path(organization, as: user)
      expect(page).to have_text(
        "#{contributor_two.name} und #{contributor_without_avatar.name} haben auf die Frage „#{request.title}” geantwortet."
      )
      expect(page).to have_link('Zur Antwort',
                                href: organization_request_path(request.organization_id, request,
                                                                anchor: "message-#{reply_by_same_contributor.id}"))

      click_link('Zur Antwort',
                 href: organization_request_path(request.organization_id, request, anchor: "message-#{reply_by_same_contributor.id}"))
      reply_text = "I'm a reply from the same contributor: #{contributor_two.name}"
      expect(page).to have_text(reply_text)
      find('p', text: reply_text).hover
      reply_path = conversations_organization_contributor_path(organization, contributor_two, reply_to: reply_by_same_contributor.id,
                                                                                              anchor: 'chat-form')
      expect(page).to have_selector("a[href='#{reply_path}']")
      find("a[href='#{reply_path}']", text: 'antworten').trigger('click')

      expect(page).to have_text("Deine Unterhaltung mit #{contributor_two.name}")
      fill_in 'message[text]', with: "Thanks for your reply #{contributor_two.name}!"
      click_button 'Absenden'

      expect(page).to have_current_path(conversations_organization_contributor_path(organization, contributor_two))
      expect(page).to have_text("Nachricht an #{contributor_two.name} wurde verschickt")
      expect(page).to have_text("Thanks for your reply #{contributor_two.name}!")

      Timecop.travel(1.week.from_now)
      visit organization_dashboard_path(organization, as: user)

      expect(page).to have_text(
        "Du hast #{contributor_two.name} und #{contributor_without_avatar.name} auf die Frage „#{request.title}” geantwortet."
      )
      expect(page).to have_text('vor 7 Tage')
      expect(page).to have_link(
        'Zur Nachricht',
        href: organization_request_path(request.organization_id, request, anchor: "message-#{Message.first.id}")
      )

      click_link('Zur Antwort',
                 href: organization_request_path(request.organization_id, request, anchor: "message-#{reply_by_same_contributor.id}"))

      reply_text = "I'm a reply from the same contributor: #{contributor_two.name}"
      expect(page).to have_text(reply_text).once
      find('p', text: reply_text).hover
      reply_path = conversations_organization_contributor_path(organization, contributor_two, reply_to: reply_by_same_contributor.id,
                                                                                              anchor: 'chat-form')
      expect(page).to have_selector("a[href='#{reply_path}']")
      find("a[href='#{reply_path}']", text: 'antworten').trigger('click')

      expect(page).to have_text("Deine Unterhaltung mit #{contributor_two.name}")
      fill_in 'message[text]', with: "This is another chat message to #{contributor_two.name}, but it doesn't count in the dashboard!"
      click_button 'Absenden'

      expect(page).to have_current_path(conversations_organization_contributor_path(organization, contributor_two))
      expect(page).to have_text("Nachricht an #{contributor_two.name} wurde verschickt")
      expect(page).to have_text("This is another chat message to #{contributor_two.name}, but it doesn't count in the dashboard!")

      visit organization_dashboard_path(organization, as: user)

      expect(page).to have_text(
        "Du hast #{contributor_two.name} und #{contributor_without_avatar.name} auf die Frage „#{request.title}” geantwortet."
      )
      expect(page).to have_link(
        'Zur Nachricht',
        href: organization_request_path(request.organization_id, request, anchor: "message-#{Message.first.id}")
      )

      visit organization_dashboard_path(organization, as: coworker)
      expect(page).to have_text(
        "#{user.name} hat #{contributor_two.name} und #{contributor_without_avatar.name} auf die Frage „#{request.title}” geantwortet."
      )

      click_link('Zur Antwort',
                 href: organization_request_path(request.organization_id, request, anchor: "message-#{reply_by_same_contributor.id}"))

      reply_text = "I'm a reply from the same contributor: #{contributor_two.name}"
      expect(page).to have_text(reply_text)
      find('p', text: reply_text).hover
      reply_path = conversations_organization_contributor_path(organization, contributor_two, reply_to: reply_by_same_contributor.id,
                                                                                              anchor: 'chat-form')
      expect(page).to have_selector("a[href='#{reply_path}']")
      find("a[href='#{reply_path}']", text: 'antworten').trigger('click')

      expect(page).to have_text("Deine Unterhaltung mit #{contributor_two.name}")

      fill_in 'message[text]', with: "This is a chat message from #{coworker.name} to #{contributor_two.name}"
      click_button 'Absenden'

      expect(page).to have_current_path(conversations_organization_contributor_path(organization, contributor_two))
      expect(page).to have_text("Nachricht an #{contributor_two.name} wurde verschickt")

      Timecop.travel(5.minutes.from_now)
      expect(page).to have_text("This is a chat message from #{coworker.name} to #{contributor_two.name}")

      visit organization_dashboard_path(organization, as: user)
      expect(page).to have_text(
        "#{coworker.name} hat #{contributor_two.name} auf „#{request.title}” geantwortet."
      )

      create(:message, :inbound, request: request, sender: another_contributor, organization: organization)
      visit organization_dashboard_path(organization, as: user)
      expect(page).to have_text(
        "#{another_contributor.name} und 2 andere haben auf die Frage „#{request.title}” geantwortet."
      )

      direct_message = create(:direct_message, text: 'I am a direct message with no request', request: nil,
                                               sender: user, organization: organization, recipient: contributor)

      create(:direct_message, text: 'I am a direct message to another contributor', request: nil,
                              sender: user, organization: organization, recipient: contributor_two)

      visit organization_dashboard_path(organization, as: user)

      expect(page).to have_text("Du hast #{contributor.name} geantwortet.")
      expect(page).to have_text("Du hast #{contributor_two.name} geantwortet.")
      click_link('Zur Nachricht',
                 href: conversations_organization_contributor_path(organization.id, contributor.id, anchor: "message-#{direct_message.id}"))

      expect(page).to have_text('I am a direct message with no request')

      visit organization_dashboard_path(organization, as: coworker)

      expect(page).to have_text("#{user.name} hat #{contributor.name} geantwortet.")
      expect(page).to have_text("#{user.name} hat #{contributor_two.name} geantwortet.")

      Timecop.travel(4.weeks.from_now)
      visit organization_dashboard_path(organization, as: user)

      # Empty State
      expect(page).to have_text('Du hast im Moment keine neuen Benachrichtigungen.')
    end
  end
end

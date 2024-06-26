# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Conversation interactions', js: false do
  let(:user) { create(:user) }
  let(:contributor) { create(:contributor, email: 'contributor@example.org') }
  let(:first_received_message) do
    create(:message, text: 'Message with the contributor as recipient 1', recipient: contributor)
  end
  let(:sent_message) do
    create(:message, sender: contributor)
  end
  let(:last_received_message) do
    create(:message, text: 'Message with the contributor as recipient 2', recipient: contributor)
  end

  before do
    first_received_message
    sent_message
    last_received_message
    visit conversations_contributor_path(contributor, as: user)
  end

  it 'can navigate to the requests view and back' do
    expect(page).to have_text(first_received_message.text)
    first_message_request_path = request_path(first_received_message.request, anchor: "message-#{first_received_message.id}")

    find("a[href='#{first_message_request_path}']", text: first_received_message.request.title).trigger('click')

    expect(page).to have_current_path(first_message_request_path.split('#').first)

    link_to_conversations = conversations_contributor_path(id: contributor.id, anchor: "message-#{first_received_message.id}")
    find("a[href='#{link_to_conversations}']").trigger('click')

    expect(page).to have_current_path(conversations_contributor_path(contributor))
  end

  it 'can answer to the latest message and assigns the message to its request' do
    last_message_request_path = request_path(last_received_message.request, anchor: "message-#{last_received_message.id}")
    expect(page).to have_link(nil, href: last_message_request_path, count: 1)

    # send a message to the contributor
    reply_text = "This is a chat message from #{user.name} to #{contributor.name}"
    fill_in 'message[text]', with: reply_text
    click_button 'Absenden'

    expect(page).to have_current_path(conversations_contributor_path(contributor))
    expect(page).to have_text("Nachricht an #{contributor.name} wurde verschickt")

    # expect that the sent message is also attached to the last messages request
    expect(page).to have_text(reply_text)
    find('p', text: reply_text)

    assert_sent_message_link = request_path(last_received_message.request, anchor: "message-#{Message.first.id}")
    expect(page).to have_link(nil, href: assert_sent_message_link)
  end

  it 'can answer to a previous message and assigns the message to its request', flaky: true do
    # find the message sent by the contributor
    sent_message_request_path = request_path(sent_message.request, anchor: "message-#{sent_message.id}")
    expect(page).to have_link(nil, href: sent_message_request_path, count: 1)

    expect(page).to have_text(sent_message.text)
    find('p', text: sent_message.text).hover
    reply_path = conversations_contributor_path(contributor, reply_to: sent_message.id, anchor: 'chat-form')
    expect(page).to have_selector("a[href='#{reply_path}']")
    find("a[href='#{reply_path}']", text: 'antworten').trigger('click')
    expect(page).to have_text("Deine Unterhaltung mit #{contributor.name}")

    # reply to the contributor
    reply_text = "This is a chat message from #{user.name} to #{contributor.name}"
    sleep 2
    fill_in 'message[text]', with: reply_text
    click_button 'Absenden'

    expect(page).to have_current_path(conversations_contributor_path(contributor))
    expect(page).to have_text("Nachricht an #{contributor.name} wurde verschickt")

    # expect that the sent message is also attached to the sent messages request
    # FIXME: sometimes the text is not filled in correctly
    expect(page).to have_text(reply_text)
    find('p', text: reply_text)
    assert_sent_message_link = request_path(sent_message.request, anchor: "message-#{Message.first.id}")
    expect(page).to have_link(nil, href: assert_sent_message_link)
  end
end

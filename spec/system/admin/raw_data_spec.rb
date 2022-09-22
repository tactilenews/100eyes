# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Raw data' do
  let(:user) { create(:user, admin: true) }
  let(:message) { create(:message) }

  it 'admin debugs raw message data' do
    visit admin_message_path(id: message.id, as: user)
    click_on 'text.json'

    switch_to_window(windows.last)

    expect(page.body).to have_text('{"text":"Hello"}')
  end
end

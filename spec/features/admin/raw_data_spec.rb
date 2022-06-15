# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Raw data', type: :feature do
  let(:user) { create(:user, admin: true) }
  let(:message) { create(:message) }

  scenario 'admin debugs raw message data' do
    visit admin_message_path(id: message.id, as: user)
    click_on 'text.json'

    expect(page.body).to eq('{"text":"Hello"}')
    expect(page.response_headers['Content-Type']).to eq('application/json')
    expect(page.response_headers['Content-Disposition']).to start_with('inline;')
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Request personalization' do
  let(:user) { create(:user) }

  context 'given two contributors'
  before(:each) do
    # `broadcast!` is stubbed in tests
    allow(Request).to receive(:broadcast!).and_call_original

    create(:contributor, first_name: 'Adam', last_name: 'Apfel', email: 'adam@example.org')
    create(:contributor, first_name: 'Zora', last_name: 'Zimmermann', email: 'zora@example.org')
  end

  it 'sending a request with placeholders' do
    visit new_request_path(as: user)

    fill_in 'Interner Titel', with: 'Personalizes request'
    fill_in 'Was möchtest du wissen?', with: 'Hi {{VORNAME}}, how are you?'

    click_button 'Frage an die Community senden'

    # TODO: This isn't really what you'd do in a feature test. However, it's an easy to
    # understand solution, given that we don't display broadcasted messages in the UI
    expect(Message.pluck(:text)).to contain_exactly('Hi Adam, how are you?', 'Hi Zora, how are you?')
  end
end

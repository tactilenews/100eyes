# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Custom errors page' do
  let(:user) { create(:user) }
  let(:message) { create(:message, creator_id: user.id) }
  before { allow_any_instance_of(MessagesController).to receive(:update).and_raise(StandardError) }

  it 'displays the custom error page' do
    # 404
    visit '/some-non-existent-endpoint'

    expect(page).to have_content('Die Seite, die du suchst, existiert nicht.')
    expect(page).to have_content('Vielleicht hast du sich bei der Adresse vertippt oder die Seite ist umgezogen.')

    # 500

    visit edit_message_path(message, as: user)

    fill_in 'message[text]', with: 'I trigger a 500 internal server error'
    click_on 'Speichern'

    expect(page).to have_content('100eyes hat einen Fehler.')
    expect(page).to have_content('Unser Otter Till-E arbeitet gern an einer Lösung, wenn du ihm schreibst support@100eyes')
  end
end

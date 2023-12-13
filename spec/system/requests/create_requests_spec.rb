# frozen_string_literal: true

# frozen_string_literal: true, frozen

require 'rails_helper'

RSpec.describe 'Create requests' do
  let(:user) { create(:user) }

  before do
    allow(Request).to receive(:broadcast!).and_call_original
  end

  it 'allows creating request' do
    visit new_request_path(as: user)

    # Does not submit without text, no file
    fill_in 'Titel', with: 'Simple create'

    click_button 'Frage an die Community senden'
    message = page.find('#request[text]').native.attribute('validationMessage')
    expect(message).to eq 'Please fill out this field.'
    expect(page).to have_current_path(new_request_path(as: user))
  end
end

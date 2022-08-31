# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Contributors', type: :feature do
  context 'as admin' do
    let(:user) { create(:user, first_name: 'Max', last_name: 'Mustermann', admin: true, password: '12345678') }
    let!(:contributor) { create(:contributor, first_name: 'Zora', last_name: 'Zimmermann') }

    scenario 'admin edits contributor' do
      visit admin_contributors_path(as: user)

      click_on 'Edit'
      fill_in 'First name', with: 'Zora Z.'
      click_on 'Update Contributor'

      expect(page).to have_text('Contributor was successfully updated.')
      expect(page).to have_text('Show Zora Z. Zimmermann')
    end
  end
end

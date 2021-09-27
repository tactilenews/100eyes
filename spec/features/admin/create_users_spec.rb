# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Auth', type: :feature do
  context 'as user with admin permissions' do
    let(:user) { create(:user, admin: true) }

    scenario 'admin creates user' do
      visit admin_users_path(as: user)

      click_on 'New user'

      fill_in 'First name', with: 'Zora'
      fill_in 'Last name', with: 'Zimmermann'
      fill_in 'Email', with: 'zimmermann@example.org'

      click_on 'Sign up'

      expect(page).to have_text('User was successfully created.')
    end
  end
end
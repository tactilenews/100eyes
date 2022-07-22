# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Users' do
  context 'as user with admin permissions' do
    let(:user) { create(:user, first_name: 'Max', last_name: 'Mustermann', admin: true, password: '12345678') }

    it 'admin creates user' do
      visit admin_users_path(as: user)

      click_on 'New user'

      fill_in 'First name', with: 'Zora'
      fill_in 'Last name', with: 'Zimmermann'
      fill_in 'Email', with: 'zimmermann@example.org'

      click_on 'Sign up'

      expect(page).to have_text('User was successfully created.')
    end

    it 'admin updates user' do
      visit edit_admin_user_path(user, as: user)
      expect { click_on 'Update User' }.not_to(change { user.reload.encrypted_password })
    end
  end
end

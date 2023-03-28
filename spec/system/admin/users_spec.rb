# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Users' do
  context 'as user with admin permissions' do
    let(:user) { create(:user, first_name: 'Max', last_name: 'Mustermann', admin: true, password: '12345678') }
    let!(:organization) { create(:organization) }

    it 'admin creates user' do
      visit admin_users_path(as: user)

      click_on 'New user'

      fill_in 'First name', with: 'Zora'
      fill_in 'Last name', with: 'Zimmermann'
      fill_in 'Email', with: 'zimmermann@example.org'
      click_on 'Sign up'
      expect(User.find_by(email: 'zimmermann@example.org').reload.organization).to eq(organization)

      expect(page).to have_text('User was successfully created.')
    end

    it 'admin creates other admin' do
      visit admin_users_path(as: user)

      click_on 'New user'

      fill_in 'First name', with: 'New'
      fill_in 'Last name', with: 'Admin'
      fill_in 'Email', with: 'new_admin@example.org'
      check 'Admin'

      click_on 'Sign up'
      expect(User.find_by(email: 'new_admin@example.org').reload.organization).to eq(nil)

      expect(page).to have_text('User was successfully created.')
    end

    describe 'admin updates user' do
      it 'updates, without changing encrypted password or otp_secret_key' do
        visit edit_admin_user_path(user, as: user)

        fill_in 'First name', with: 'UpdatedZora'
        expect { click_on 'Update User' }.not_to(change { user.reload.encrypted_password })

        visit edit_admin_user_path(user, as: user)

        uncheck 'Otp enabled'
        expect { click_on 'Update User' }.to(change { user.reload.otp_secret_key })
      end
    end
  end
end

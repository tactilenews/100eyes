# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Auth', type: :feature do
  context 'as signed-out user' do
    scenario 'user tries to access' do
      visit admin_users_path
      expect(page).to have_http_status(:not_found)
    end
  end

  context 'as user without admin permissions' do
    let(:user) { create(:user, admin: false) }

    scenario 'user visits the main app' do
      visit dashboard_path(as: user)
      expect(page).not_to have_link('Admin')
    end

    scenario 'user tries to access admin dashboard' do
      visit admin_users_path(as: user)
      expect(page).to have_http_status(:not_found)
    end
  end

  context 'as user with admin permissions' do
    let(:user) { create(:user, admin: true) }

    scenario 'user visists the admin dashboard' do
      visit dashboard_path(as: user)

      click_link 'Admin'

      expect(page).to have_http_status(:ok)
      expect(page).to have_link('New user')
    end
  end
end

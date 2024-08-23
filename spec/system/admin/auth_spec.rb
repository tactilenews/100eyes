# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Auth' do
  let(:organization) { create(:organization) }

  describe 'as signed-out user' do
    it 'user tries to access' do
      visit admin_users_path
      expect(page).to have_http_status(:not_found)
    end
  end

  describe 'as user without admin permissions' do
    let(:user) { create(:user, admin: false) }

    it 'user visits the main app' do
      visit organization_dashboard_path(organization, as: user)
      expect(page).not_to have_link('Admin')
    end

    it 'user tries to access admin dashboard' do
      visit admin_users_path(as: user)
      expect(page).to have_http_status(:not_found)
    end
  end

  describe 'as user with admin permissions' do
    let(:user) { create(:user, admin: true) }

    it 'user visits the admin dashboard from the main app' do
      visit organization_dashboard_path(organization, as: user)

      click_link 'Admin'

      expect(page).to have_http_status(:ok)

      expect(page).to have_link('New user')
    end
  end
end

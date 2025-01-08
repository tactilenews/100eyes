# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Auth' do
  let(:organization) { create(:organization) }

  it 'only allows access to admin' do
    visit admin_users_path
    expect(page).to have_http_status(:not_found)

    non_admin_user = create(:user, admin: false)
    visit organization_dashboard_path(organization, as: non_admin_user)
    expect(page).not_to have_link('Admin')

    visit admin_users_path(as: non_admin_user)
    expect(page).to have_http_status(:not_found)

    admin = create(:user, admin: true)

    visit organization_dashboard_path(organization, as: admin)
    click_link 'Admin'

    expect(page).to have_http_status(:ok)

    expect(page).to have_link('organization erstellen')
  end
end

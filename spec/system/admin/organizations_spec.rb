# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Organizations' do
  context 'as admin' do
    let(:admin) { create(:user, admin: true) }
    let!(:organization) { create(:organization, name: 'Org placeholder name') }

    it 'admin edits organization' do
      visit admin_organizations_path(as: admin)

      click_on 'Edit'
      fill_in 'Name', with: 'Real name'
      fill_in 'Whats app more info message', with: 'More info. Unsubscribe?'
      click_on 'Update Organization'

      expect(page).to have_text('Organization was successfully updated.')
      expect(page).to have_text('Show Real name')
      expect(page).to have_content('More info. Unsubscribe?')
    end
  end
end

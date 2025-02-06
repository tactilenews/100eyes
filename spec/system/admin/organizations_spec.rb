# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Organizations' do
  context 'as admin' do
    let(:admin) { create(:user, admin: true) }
    let!(:organization) { create(:organization, name: 'Org placeholder name') }

    it 'admin edits organization' do
      visit admin_organizations_path(as: admin)

      click_on 'Editieren'
      fill_in 'Name', with: 'Real name'
      fill_in 'Whatsapp Mehr Info Text', with: 'More info. Unsubscribe?'
      click_on 'Organization aktualisieren'

      expect(page).to have_text('Organization wurde erfolgreich aktualisiert.')
      expect(page).to have_text('Real name anzeigen')
      expect(page).to have_content('More info. Unsubscribe?')
    end
  end
end

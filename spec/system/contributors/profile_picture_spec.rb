# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Profile pictures' do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:contributor) { create(:contributor, organization: organization) }

  it 'Editor uploads new picture' do
    visit organization_contributor_path(organization, contributor, as: user)

    expect(page).to have_css('.Avatar svg')

    new_profile_picture = File.expand_path('../../fixtures/files/profile_picture.jpg', __dir__)
    file_input = find('input[id="contributor[avatar]"]', visible: false)
    file_input.attach_file(new_profile_picture)
    find_button('Profilbild ändern', class: 'SubmitButton').trigger('click')

    # Successfully renders the contributor profile and displays
    # the new profile picture
    expect(page).to have_css('.Avatar img[src$="profile_picture.jpg"]')
  end

  context 'invalid avatar type' do
    let!(:active_contributors) { create_list(:contributor, 2) }
    let!(:inactive_contributor) { create(:contributor, deactivated_at: Time.current) }
    let!(:unsubscribed_contributor) { create(:contributor, unsubscribed_at: Time.current) }

    it 'renders show with error message' do
      visit organization_contributor_path(organization, contributor, as: user)

      within('#contributors-sidebar') do
        active_contributors.each do |contributor|
          expect(page).to have_content(contributor.name)
        end
        expect(page).not_to have_content(inactive_contributor.name)
        expect(page).not_to have_content(unsubscribed_contributor.name)
      end

      expect(page).to have_css('.Avatar svg')

      new_profile_picture = File.expand_path('../../fixtures/files/invalid_profile_picture.pdf', __dir__)
      file_input = find('input[id="contributor[avatar]"]', visible: false)
      file_input.attach_file(new_profile_picture)
      find_button('Profilbild ändern', class: 'SubmitButton').trigger('click')

      # Successfully renders the contributor profile
      expect(page).to have_content("Informationen zu #{contributor.name} sind ungültig")
      expect(page).to have_css('.Avatar svg')

      within('#contributors-sidebar') do
        active_contributors.each do |contributor|
          expect(page).to have_content(contributor.name)
        end
        expect(page).not_to have_content(inactive_contributor.name)
        expect(page).not_to have_content(unsubscribed_contributor.name)
      end
    end
  end
end

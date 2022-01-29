# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Profile pictures', type: :feature do
  let(:user) { create(:user) }
  let!(:contributor) { create(:contributor) }

  scenario 'Editor uploads new picture' do
    visit contributor_path(contributor, as: user)

    expect(page).to have_css('.Avatar svg')

    new_profile_picture = File.expand_path('../../fixtures/files/profile_picture.jpg', __dir__)
    attach_file('Profilbild', new_profile_picture)
    click_button('Profilbild ändern', class: 'SubmitButton')

    # Successfully renders the contributor profile and displays
    # the new profile picture
    expect(page).to have_css('.Avatar img[src$="profile_picture.jpg"]')
  end

  scenario 'Editor uploads invalid file type' do
    visit contributor_path(contributor, as: user)

    expect(page).to have_css('.Avatar svg')

    new_profile_picture = File.expand_path('../../fixtures/files/invalid_profile_picture.pdf', __dir__)
    attach_file('Profilbild', new_profile_picture)
    click_button('Profilbild ändern', class: 'SubmitButton')

    # Successfully renders the contributor profile
    expect(page).to have_css('.Avatar svg')
  end
end

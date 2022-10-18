# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Profile pictures' do
  let(:user) { create(:user) }
  let!(:contributor) { create(:contributor) }

  it 'Editor uploads new picture' do
    visit contributor_path(contributor, as: user)

    expect(page).to have_css('.Avatar svg')

    new_profile_picture = File.expand_path('../../fixtures/files/profile_picture.jpg', __dir__)
    file_input = find('input[id="contributor[avatar]"]', visible: false)
    file_input.attach_file(new_profile_picture)
    find_button('Profilbild ändern', class: 'SubmitButton').trigger('click')

    # Successfully renders the contributor profile and displays
    # the new profile picture
    expect(page).to have_css('.Avatar img[src$="profile_picture.jpg"]')
  end

  it 'Editor uploads invalid file type' do
    visit contributor_path(contributor, as: user)

    expect(page).to have_css('.Avatar svg')

    new_profile_picture = File.expand_path('../../fixtures/files/invalid_profile_picture.pdf', __dir__)
    file_input = find('input[id="contributor[avatar]"]', visible: false)
    file_input.attach_file(new_profile_picture)
    find_button('Profilbild ändern', class: 'SubmitButton').trigger('click')

    # Successfully renders the contributor profile
    expect(page).to have_css('.Avatar svg')
  end
end

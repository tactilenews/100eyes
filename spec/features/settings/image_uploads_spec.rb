# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Image uploads', type: :feature do
  let(:user) { create(:user) }
  before(:each) { allow(Setting).to receive(:project_name).and_return('Die Lokal-Community!') }
  let(:jwt) { JsonWebToken.encode({ invite_code: 'ONBOARDING_TOKEN', action: 'onboarding' }) }

  scenario 'Upload new onboarding logo' do
    visit onboarding_path(jwt: jwt)
    expect(page).to have_css('header', text: 'Die Lokal-Community!')
    expect(page).not_to have_css('img')

    visit settings_path(as: user)

    # Image inputs in settings form are empty
    expect(page).to have_text('Noch kein Bild hochgeladen', count: 2)

    page.find_field('Logo', visible: :all).attach_file('example-image.png')
    click_on 'Speichern'

    # The logo image input is not empty any more
    expect(page).to have_text('Noch kein Bild hochgeladen', count: 1)
    expect(page).to have_text('example-image.png')

    visit onboarding_path(jwt: jwt)
    expect(page).to have_css('header img[alt="Die Lokal-Community!"]')
  end

  scenario 'Upload new onboarding hero' do
    visit onboarding_path(jwt: jwt)
    expect(page).not_to have_css('main img')

    visit settings_path(as: user)
    page.find_field('Header-Bild', visible: :all).attach_file('example-image.png')
    click_on 'Speichern'

    visit onboarding_path(jwt: jwt)
    expect(page).to have_css('main img')
  end
end

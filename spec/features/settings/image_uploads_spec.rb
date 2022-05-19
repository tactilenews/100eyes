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
    attach_file 'Logo', 'example-image.png'
    click_on 'Speichern'

    visit onboarding_path(jwt: jwt)
    expect(page).to have_css('header img[alt="Die Lokal-Community!"]')
  end

  scenario 'Upload new onboarding hero' do
    visit onboarding_path(jwt: jwt)
    expect(page).not_to have_css('main img')

    visit settings_path(as: user)
    attach_file 'Header-Bild', 'example-image.png'
    click_on 'Speichern'

    visit onboarding_path(jwt: jwt)
    expect(page).to have_css('main img')
  end
end

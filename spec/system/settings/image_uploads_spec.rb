# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Image uploads' do
  let!(:organization) { create(:organization, project_name: 'Die Lokal-Community!') }
  let(:user) { create(:user, organizations: [organization]) }
  let(:jwt) { JsonWebToken.encode({ invite_code: 'ONBOARDING_TOKEN', action: 'onboarding' }) }

  it 'Upload new onboarding logo' do
    visit organization_onboarding_path(organization, jwt: jwt)

    expect(page).to have_css('header', text: 'DIE LOKAL-COMMUNITY!')
    expect(page).not_to have_css('img')

    visit organization_settings_path(organization, as: user)

    # Image inputs in settings form are empty
    expect(page).to have_text('Kein Bild ausgewählt', count: 2)

    new_onboarding_logo = File.expand_path('../../fixtures/files/example-image.png', __dir__)
    find_field('Logo', visible: :all).attach_file(new_onboarding_logo)
    click_on 'Speichern'

    # The logo image input is not empty any more
    expect(page).to have_text('Kein Bild ausgewählt', count: 1)
    expect(page).to have_text('example-image.png')

    visit organization_onboarding_path(organization, jwt: jwt)
    expect(page).to have_css('header img[alt="Die Lokal-Community!"]')
  end

  it 'Upload new onboarding hero' do
    visit organization_onboarding_path(organization, jwt: jwt)
    expect(page).not_to have_css('main img')

    visit organization_settings_path(organization, as: user)

    new_onboarding_hero = File.expand_path('../../fixtures/files/example-image.png', __dir__)
    find_field('Header-Bild', visible: :all).attach_file(new_onboarding_hero)
    click_on 'Speichern'

    # The logo image input is not empty any more
    expect(page).to have_text('Kein Bild ausgewählt', count: 1)
    expect(page).to have_text('example-image.png')

    visit organization_onboarding_path(organization, jwt: jwt)
    expect(page).to have_css('main img')
  end
end

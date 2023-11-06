# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Permissions' do
  let(:user) { create(:user) }

  it 'Exposes certain fields only to admin' do
    visit settings_path(as: user)

    # Channels
    Setting.channels.each do |key, _value|
      expect(page).not_to have_field(key.to_s.camelize, id: "setting[channels][#{key}]")
    end

    # Data protection link
    expect(page).not_to have_field('Link zur Datenschutzerklärung')
    expect(page).not_to have_text(/Der Link wird während des Onboardings in der Fußzeile angezeigt. Vor der Anmeldung müssen neue/)

    # Data protection addtional info
    expect(page).not_to have_field('Platz für zusätzliche Erklärung zum Datenschutz')

    # Imprint link
    expect(page).not_to have_field('Link zum Impressum')
    expect(page).not_to have_text('Der Link wird während des Onboardings in der Fußzeile angezeigt.')

    # Addtional consent
    expect(page).not_to have_text('Zusätzliches Einverständnis während des Onboardings')
    expect(page).not_to have_field('Nach zusätzlichem Einverständnis fragen')
    expect(page).not_to have_text(/Falls aktiviert, wird neuen Community-Mitgliedern eine zusätzliche, optionale Checkbox angezeigt./)

    expect(page).not_to have_field('Überschrift')

    expect(page).not_to have_field('Text', id: 'setting[onboarding_additional_consent_text]')

    user.update(admin: true)
    visit settings_path(as: user)

    # Channels
    Setting.channels.each do |key, _value|
      expect(page).to have_field(key.to_s.camelize, id: "setting[channels][#{key}]")
    end

    # Data protection link
    expect(page).to have_field('Link zur Datenschutzerklärung')
    expect(page).to have_text(/Der Link wird während des Onboardings in der Fußzeile angezeigt. Vor der Anmeldung müssen neue/)

    # Data protection addtional info
    expect(page).to have_field('Platz für zusätzliche Erklärung zum Datenschutz')

    # Imprint link
    expect(page).to have_field('Link zum Impressum')
    expect(page).to have_text('Der Link wird während des Onboardings in der Fußzeile angezeigt.')

    # Addtional consent
    expect(page).to have_text('Zusätzliches Einverständnis während des Onboardings')
    expect(page).to have_field('Nach zusätzlichem Einverständnis fragen')
    expect(page).to have_text(/Falls aktiviert, wird neuen Community-Mitgliedern eine zusätzliche, optionale Checkbox angezeigt./)

    expect(page).to have_field('Überschrift')

    expect(page).to have_field('Text', id: 'setting[onboarding_additional_consent_text]')
  end
end

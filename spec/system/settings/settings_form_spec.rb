# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Settings' do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  it 'Exposes certain fields only to admin' do
    visit organization_settings_path(organization, as: user)

    fill_in 'Projekt-Name', with: 'Updated project name'

    within('section[data-testid="onboarding-section"]') do
      onboarding_logo = page.all(
        :xpath,
        "//div[@aria-labelledby='label-organization[onboarding_logo]']"
      ).first
      onboarding_logo.click_button 'Bild auswählen'
      image_file = File.expand_path('../../fixtures/files/example-image.png', __dir__)
      find_field('organization[onboarding_logo]', visible: :all).attach_file(image_file)

      fill_in 'Unterzeile', with: 'This is my byline'

      onboarding_hero = page.all(
        :xpath,
        "//div[@aria-labelledby='label-organization[onboarding_hero]']"
      ).first
      onboarding_hero.click_button 'Bild auswählen'
      image_file = File.expand_path('../../fixtures/files/profile_picture.jpg', __dir__)
      find_field('organization[onboarding_hero]', visible: :all).attach_file(image_file)

      fill_in 'Titel', with: 'Onboarding title'
      fill_in 'Text', with: "**Note:** This document is itself written using Markdown; you
      can [see the source for it by adding '.text' to the URL](/projects/markdown/syntax.text)."
    end

    within('section[data-testid="onboarding-success-section"]') do
      fill_in 'Titel', with: 'Congrats, it was a success!'
      fill_in 'Text', with: 'We will be in touch.'
    end

    within('section[data-testid="onboarding-unauthorized-section"]') do
      fill_in 'Titel', with: 'Oh no, something went wrong!'
      fill_in 'Text', with: 'Better talk to someone'
    end

    within('section[data-testid="signal-section"]') do
      fill_in 'Fehler-Nachricht bei unbekannten Inhalten', with: "sorry, we don't accept that"
    end

    within('section[data-testid="telegram-section"]') do
      fill_in 'Fehler-Nachricht bei unbekannten Inhalten', with: "sorry, we don't accept that"
      fill_in 'Fehler-Nachricht bei unbekanntem Telegram-Absender', with: "we don't know who you are"
    end

    within('section[data-testid="threema-section"]') do
      fill_in 'Fehler-Nachricht bei unbekannten Inhalten', with: "sorry, we don't accept that"
    end

    click_on 'Speichern'

    expect(page).to have_current_path(organization_settings_path(organization), ignore_query: true)
    expect(page).to have_content('Einstellungen erfolgreich gespeichert!')
    expect(page).to have_css("img[src*='example-image.png']")
    expect(page).to have_field('Unterzeile', with: 'This is my byline')
    expect(page).to have_css("img[src*='profile_picture.jpg']")
    expect(page).to have_field('Titel', with: 'Onboarding title')
    expect(page).to have_field('Text', with: "**Note:** This document is itself written using Markdown; you
      can [see the source for it by adding '.text' to the URL](/projects/markdown/syntax.text).")
    expect(page).to have_field('Titel', with: 'Congrats, it was a success!')
    expect(page).to have_field('Text', with: 'We will be in touch.')
    expect(page).to have_field('Titel', with: 'Oh no, something went wrong!')
    expect(page).to have_field('Text', with: 'Better talk to someone')
    within('section[data-testid="signal-section"]') do
      expect(page).to have_field('Fehler-Nachricht bei unbekannten Inhalten', with: "sorry, we don't accept that")
    end

    within('section[data-testid="telegram-section"]') do
      expect(page).to have_field('Fehler-Nachricht bei unbekannten Inhalten', with: "sorry, we don't accept that")
      expect(page).to have_field('Fehler-Nachricht bei unbekanntem Telegram-Absender', with: "we don't know who you are")
    end

    within('section[data-testid="threema-section"]') do
      expect(page).to have_field('Fehler-Nachricht bei unbekannten Inhalten', with: "sorry, we don't accept that")
    end
  end
end

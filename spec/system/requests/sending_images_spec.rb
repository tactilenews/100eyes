# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Sending image files', js: true do
  let(:user) { create(:user) }
  let(:organization) { create(:organization) }

  context 'given contributors' do
    before(:each) do
      # `broadcast!` is stubbed in tests
      allow(Request).to receive(:broadcast!).and_call_original

      create(:contributor, email: 'adam@example.org')
      create(:contributor, signal_phone_number: '+4912345678')
      create(:contributor, telegram_id: 125_689)
      create(:contributor, :skip_validations, threema_id: '12345678')
    end

    it 'sending a request with image files', flaky: true do
      visit new_organization_request_path(organization, as: user)

      # With no text, no file
      fill_in 'Titel', with: 'No text, no files'

      click_button 'Frage an die Community senden'
      message = page.find('textarea[name="request[text]"]').evaluate_script('this.validationMessage')
      expect(message).to eq 'Please fill out this field.'
      expect(page).to have_current_path(new_organization_request_path(organization), ignore_query: true)

      # With no text, with file
      visit new_organization_request_path(organization, as: user)

      fill_in 'Titel', with: 'Message with files, no text'

      find_button('Bilder anhängen').trigger('click')
      image_file = File.expand_path('../../fixtures/files/example-image.png', __dir__)
      find_field('request_files', visible: :all).attach_file(image_file)

      click_button 'Frage an die Community senden'

      expect(page).to have_content('Message with files, no text')
      expect(page).to have_current_path(organization_request_path(organization, Request.first))

      # With text
      visit new_organization_request_path(organization, as: user)

      fill_in 'Titel', with: 'Message with files'
      fill_in 'Was möchtest du wissen?', with: 'Did you get my image?'

      # Non-image file
      click_button 'Bilder anhängen'
      image_file = File.expand_path('../../fixtures/files/invalid_profile_picture.pdf', __dir__)
      find_field('request_files', visible: :all).attach_file(image_file)

      expect(page).to have_content('Kein gültiges Bildformat. Bitte senden Sie Bilder als jpg, png oder gif.')

      click_button 'Frage an die Community senden'

      expect(page).to have_current_path(new_organization_request_path(organization), ignore_query: true)
      expect(page).to have_content('Kein gültiges Bildformat. Bitte senden Sie Bilder als jpg, png oder gif.')

      # Image file
      click_button 'Bilder anhängen'
      image_file = File.expand_path('../../fixtures/files/example-image.png', __dir__)
      find_field('request_files', visible: :all).attach_file(image_file)

      within('#file-preview') do
        expect(page).to have_css('img')
        expect(page).to have_css('figcaption#caption', text: 'Did you get my image?')
      end

      expect(page).to have_content('Angehängte Bilder')
      expect(page).to have_css('p.RequestForm-filename', text: 'example-image.png')
      expect(page).to have_css(
        'button.RequestForm-removeListItemButton[data-action="request-form#removeImage"][data-request-form-image-index-value="0"]'
      )
      click_button 'x'

      expect(page).not_to have_content('Angehängte Bilder')
      expect(page).to have_no_css('p.RequestForm-filename', text: 'example-image.png')
      expect(page).to have_no_css(
        'button.RequestForm-removeListItemButton[data-action="request-form#removeImage"][data-request-form-image-index-value="0"]'
      )

      within('figure.ChatPreview') do
        expect(page).to have_no_css('img')
        expect(page).to have_no_css('figcaption#caption', text: 'Did you get my image?')
      end

      click_button 'Bilder anhängen'
      image_file = File.expand_path('../../fixtures/files/example-image.png', __dir__)
      find_field('request_files', visible: :all).attach_file(image_file)

      click_button 'Frage an die Community senden'

      expect(page).to have_content('Did you get my image?')
      expect(page).to have_current_path(organization_request_path(organization, Request.first))

      within('.PageHeader') do
        expect(page).to have_css("img[src*='example-image.png']")
      end

      within('.CardMetrics') do
        expect(page).to have_content('0/4 haben geantwortet')
      end
    end
  end
end

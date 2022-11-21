# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Sending image files' do
  let(:user) { create(:user) }

  context 'given contributors'
  before(:each) do
    # `broadcast!` is stubbed in tests
    allow(Request).to receive(:broadcast!).and_call_original

    create(:contributor, email: 'adam@example.org')
    create(:contributor, signal_phone_number: '+4912345678', signal_onboarding_completed_at: Time.current)
    create(:contributor, telegram_id: 125_689)
    build(:contributor, threema_id: '12345678').tap { |contributor| contributor.save(validate: false) }
  end

  it 'sending a request with image files' do
    visit new_request_path(as: user)

    fill_in 'Interner Titel', with: 'Message with files'
    fill_in 'Was möchtest du wissen?', with: 'Did you get my image?'

    click_button 'Bild anhängen'
    image_file = File.expand_path('../../fixtures/files/example-image.png', __dir__)
    find_field('request_files', visible: :all).attach_file(image_file)

    within('#file-preview') do
      expect(page).to have_css('img')
      expect(page).to have_css('figcaption#caption', text: 'Did you get my image?')
    end

    click_button 'Frage an die Community senden'

    expect(page).to have_current_path(request_path(Request.first))

    within('.PageHeader') do
      expect(page).to have_css("img[src*='example-image.png']")
    end

    within('.CardMetrics') do
      expect(page).to have_content('0/4 haben geantwortet')
    end
  end
end

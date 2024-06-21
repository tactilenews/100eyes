# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Onboarding' do
  let!(:organization) do
    create(:organization,
           signal_server_phone_number: nil,
           onboarding_unauthorized_heading: 'Something went wrong',
           onboarding_unauthorized_text: "Don't panic!",
           onboarding_title: 'Cool Project',
           onboarding_page: '### Wo?',
           onboarding_success_heading: 'You did it!',
           onboarding_success_text: 'Welcome to the team!!',
           onboarding_allowed: { threema: true, telegram: true, email: false, signal: true, whats_app: true })
  end
  let(:invalidated_jwt) do
    JsonWebToken.encode({ invite_code: SecureRandom.base64(16), action: 'onboarding', organization_id: organization.id })
  end
  let!(:invalidate_jwt) { create(:json_web_token, invalidated_jwt: invalidated_jwt) }

  it 'Supports onboarding new contributors' do
    # Valid JWT, no configured channels
    jwt = JsonWebToken.encode({ invite_code: SecureRandom.base64(16), action: 'onboarding', organization_id: organization.id })
    visit onboarding_path(jwt: jwt)

    expect(page).to have_content("The page you were looking for doesn't exist")

    organization.update!(signal_server_phone_number: '+491512345678',
                         onboarding_allowed: { threema: true, telegram: true, email: true, signal: true, whats_app: true })
    # Invalid JWT
    visit onboarding_path(jwt: 'invalid_jwt')

    expect(page).to have_content('Something went wrong')
    expect(page).to have_content("Don't panic!")

    # Invalidated JWT
    visit onboarding_path(jwt: invalidated_jwt)

    expect(page).to have_content('Something went wrong')
    expect(page).to have_content("Don't panic!")

    # Valid JWT
    jwt = JsonWebToken.encode({ invite_code: SecureRandom.base64(16), action: 'onboarding', organization_id: organization.id })
    visit onboarding_path(jwt: jwt)

    expect(page).to have_content('Cool Project')
    expect(page).to have_content('Wo?')

    # With email and signal configured
    within('.OnboardingChannelButtons') do
      expect(page).to have_link(class: 'Button').twice
      expect(page).to have_link('E-Mail', class: 'Button', href: "/onboarding/email?jwt=#{jwt}")
      expect(page).to have_link('Signal', class: 'Button', href: "/onboarding/signal?jwt=#{jwt}")
    end
    api_key = 'valid_api_key'
    organization.update!(threemarb_api_identity: '*100EYES', three_sixty_dialog_client_api_key: api_key, telegram_bot_api_key: api_key)

    visit onboarding_path(jwt: jwt)

    within('.OnboardingChannelButtons') do
      expect(page).to have_link(class: 'Button').exactly(5)
      expect(page).to have_link('Threema', class: 'Button', href: "/onboarding/threema?jwt=#{jwt}")
      expect(page).to have_link('WhatsApp', class: 'Button', href: "/onboarding/whats-app?jwt=#{jwt}")
      expect(page).to have_link('Telegram', class: 'Button', href: "/onboarding/telegram?jwt=#{jwt}")

      click_on 'WhatsApp'
    end

    expect(page).to have_current_path(onboarding_whats_app_path(jwt: jwt))

    fill_in 'Vorname', with: 'New'
    fill_in 'Nachname', with: 'Contributor'
    fill_in 'Handynummer', with: '015123456789'
    check 'Einwilligung zur Datenverarbeitung'

    click_on 'Anmeldung abschließen'

    expect(page).to have_current_path(onboarding_success_path)
    expect(page).to have_content('You did it!')
    expect(page).to have_content('Welcome to the team!!')

    visit onboarding_path(jwt: jwt)

    expect(page).to have_content('Something went wrong')
    expect(page).to have_content("Don't panic!")
  end
end

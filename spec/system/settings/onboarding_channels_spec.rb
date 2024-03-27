# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Configuring Onboarding Channels' do
  let(:admin) { create(:user, admin: true) }
  let(:organization) { create(:organization) }
  let(:jwt_payload) { { invite_code: SecureRandom.base64(16), action: 'onboarding', organization_id: organization.id } }
  let(:jwt) do
    JsonWebToken.encode(jwt_payload)
  end

  before do
    allow(Setting).to receive(:threemarb_api_identity).and_return(nil)
    allow(Setting).to receive(:telegram_bot_api_key).and_return(nil)
    allow(Setting).to receive(:signal_server_phone_number).and_return(nil)
    allow(Setting).to receive(:whats_app_configured?).and_return(false)
    # defaults to true as Postmark handles user management
    allow(Setting).to receive(:postmark_api_token).and_return('valid_api_token')
  end

  it 'allows activating and deactivating onboarding channels' do
    visit settings_path(as: admin)

    # With no messengers configured
    within('.OnboardingChannelsCheckboxes') do
      Setting.channels.each_key do |key|
        checked_status = !key.eql?(:email)
        expect(page).to have_field(key.to_s.camelize, id: "setting[channels][#{key}]", checked: checked_status)
      end
    end

    allow(Setting).to receive(:threemarb_api_identity).and_return('valid_api_identity')
    visit settings_path(as: admin)

    within('.OnboardingChannelsCheckboxes') do
      expect(page).to have_field('Threema', id: 'setting[channels][threema]', checked: true)
    end

    allow(Setting).to receive(:telegram_bot_api_key).and_return(nil)
    visit settings_path(as: admin)

    within('.OnboardingChannelsCheckboxes') do
      expect(page).to have_field('Telegram', id: 'setting[channels][telegram]', checked: true)
    end

    allow(Setting).to receive(:signal_server_phone_number).and_return('+491234567')
    visit settings_path(as: admin)

    within('.OnboardingChannelsCheckboxes') do
      expect(page).to have_field('Signal', id: 'setting[channels][signal]', checked: true)
    end

    allow(Setting).to receive(:whats_app_configured?).and_return(true)
    visit settings_path(as: admin)

    within('.OnboardingChannelsCheckboxes') do
      expect(page).to have_field('WhatsApp', id: 'setting[channels][whats_app]', checked: true)
    end

    # Uncheck email
    within('.OnboardingChannelsCheckboxes') do
      uncheck 'Email'
    end

    click_on 'Speichern'
    expect(page).to have_current_path(settings_path, ignore_query: true)

    within('.OnboardingChannelsCheckboxes') do
      Setting.channels.keys.map(&:to_sym).each do |key|
        checked_status = !key.eql?(:email)
        expect(page).to have_field(key.to_s.camelize, id: "setting[channels][#{key}]", checked: checked_status)
      end
    end

    visit onboarding_path(jwt: jwt)

    within('.OnboardingChannelButtons') do
      Setting.channels.keys.map(&:to_sym).each do |key|
        unless key.eql?(:email)
          expect(page).to have_link(key.to_s.camelize, class: 'Button', href: "/onboarding/#{key.to_s.dasherize}?jwt=#{jwt}")
        end
      end
    end
  end
end

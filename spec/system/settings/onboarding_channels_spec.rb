# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Configuring Onboarding Channels' do
  let(:admin) { create(:user, admin: true) }
  let(:organization) { create(:organization) }
  let(:jwt_payload) { { invite_code: SecureRandom.base64(16), action: 'onboarding', organization_id: organization.id } }
  let(:jwt) do
    JsonWebToken.encode(jwt_payload)
  end
  let(:configured_channels) { %i[email signal whats_app telegram] }

  it 'allows activating and deactivating onboarding channels' do
    visit settings_path(as: admin)

    # With no Threema configured in .env.test.local
    within('.OnboardingChannelsCheckboxes') do
      Setting.channels.each_key do |key|
        if key.to_sym.in?(configured_channels)
          expect(page).to have_field(key.to_s.camelize, id: "setting[channels][#{key}][allow_onboarding]", checked: true)
        else
          expect(page).not_to have_field(key.to_s.camelize, id: "setting[channels][#{key}][allow_onboarding]")
        end
      end

      # Uncheck email
      uncheck 'Email'
    end

    click_on 'Speichern'
    expect(page).to have_current_path(settings_path, ignore_query: true)

    within('.OnboardingChannelsCheckboxes') do
      configured_channels.each do |channel|
        if channel.eql?(:email)
          expect(page).to have_field(channel.to_s.camelize, id: "setting[channels][#{channel}][allow_onboarding]", checked: false)
        else
          expect(page).to have_field(channel.to_s.camelize, id: "setting[channels][#{channel}][allow_onboarding]", checked: true)
        end
      end
    end

    visit onboarding_path(jwt: jwt)

    within('.OnboardingChannelButtons') do
      configured_channels.each do |channel|
        if channel.eql?(:email)
          expect(page).not_to have_link(channel.to_s.camelize)
        else
          expect(page).to have_link(channel.to_s.camelize, class: 'Button', href: "/onboarding/#{channel.to_s.dasherize}?jwt=#{jwt}")
        end
      end
    end
  end
end

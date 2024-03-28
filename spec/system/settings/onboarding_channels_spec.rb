# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Configuring Onboarding Channels' do
  let(:admin) { create(:user, admin: true) }
  let(:organization) { create(:organization) }
  let(:jwt_payload) { { invite_code: SecureRandom.base64(16), action: 'onboarding', organization_id: organization.id } }
  let(:jwt) do
    JsonWebToken.encode(jwt_payload)
  end

  it 'allows activating and deactivating onboarding channels' do
    visit settings_path(as: admin)

    # All activated by default
    within('.OnboardingChannelsCheckboxes') do
      Setting.channels.each_key do |key|
        expect(page).to have_field(key.to_s.camelize, id: "setting[channels][#{key}]", checked: true)
      end

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

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Configuring Onboarding Channels' do
  let(:admin) { create(:user, admin: true) }
  let(:organization) { create(:organization) }
  let(:jwt_payload) { { invite_code: SecureRandom.base64(16), action: 'onboarding', organization_id: organization.id } }
  let(:jwt) do
    JsonWebToken.encode(jwt_payload)
  end
  let(:default_configured_channels) do
    {
      threema: { configured: Setting.threema_configured?, allow_onboarding: Setting.threema_configured? },
      telegram: { configured: Setting.telegram_configured?, allow_onboarding: Setting.telegram_configured? },
      email: { configured: Setting.email_configured?, allow_onboarding: Setting.email_configured? },
      signal: { configured: Setting.signal_configured?, allow_onboarding: Setting.signal_configured? },
      whats_app: { configured: Setting.whats_app_configured?, allow_onboarding: Setting.whats_app_configured? }
    }
  end
  let(:with_all_messengers_configured) do
    {
      threema: { configured: Setting.threema_configured?, allow_onboarding: Setting.threema_configured? },
      telegram: { configured: Setting.telegram_configured?, allow_onboarding: Setting.telegram_configured? },
      email: { configured: Setting.email_configured?, allow_onboarding: Setting.email_configured? },
      signal: { configured: Setting.signal_configured?, allow_onboarding: Setting.signal_configured? },
      whats_app: { configured: Setting.whats_app_configured?, allow_onboarding: Setting.whats_app_configured? }
    }
  end
  let(:channels) { Setting.find_by(var: :channels).value }

  before do
    allow(Setting).to receive(:threema_configured?).and_return(false)
    allow(Setting).to receive(:telegram_configured?).and_return(false)
    # enabled by default because Postmark handles user management
    allow(Setting).to receive(:email_configured?).and_return(true)
    allow(Setting).to receive(:signal_configured?).and_return(false)
    allow(Setting).to receive(:whats_app_configured?).and_return(false)
    allow(Setting).to receive(:channels).and_return(default_configured_channels)
  end

  it 'allows activating and deactivating onboarding channels' do
    visit settings_path(as: admin)

    # With no messengers configured
    within('.OnboardingChannelsCheckboxes') do
      channels.each_key do |key|
        if key.to_sym.eql?(:email)
          expect(page).to have_field(key.to_s.camelize, id: "setting[channels][#{key}][allow_onboarding]", checked: true)
        else
          expect(page).not_to have_field(key.to_s.camelize, id: "setting[channels][#{key}][allow_onboarding]")
        end
      end
    end

    allow(Setting).to receive(:threema_configured?).and_return(true)
    allow(Setting).to receive(:telegram_configured?).and_return(true)
    allow(Setting).to receive(:signal_configured?).and_return(true)
    allow(Setting).to receive(:whats_app_configured?).and_return(true)
    allow(Setting).to receive(:channels).and_return(with_all_messengers_configured)

    visit settings_path(as: admin)

    within('.OnboardingChannelsCheckboxes') do
      channels.each_key do |key|
        expect(page).to have_field(key.to_s.camelize, id: "setting[channels][#{key}][allow_onboarding]", checked: true)
      end

      # Uncheck email
      uncheck 'Email'
    end

    click_on 'Speichern'
    expect(page).to have_current_path(settings_path, ignore_query: true)

    within('.OnboardingChannelsCheckboxes') do
      channels.each_key do |key|
        if key.to_sym.eql?(:email)
          expect(page).to have_field(key.to_s.camelize, id: "setting[channels][#{key}][allow_onboarding]", checked: false)
        else
          expect(page).to have_field(key.to_s.camelize, id: "setting[channels][#{key}][allow_onboarding]", checked: true)
        end
      end
    end

    visit onboarding_path(jwt: jwt)

    within('.OnboardingChannelButtons') do
      channels.select { |_key, value| value[:configured] && value[:allow_onboarding] }.keys.map(&:to_sym).each do |key|
        expect(page).to have_link(key.to_s.camelize, class: 'Button', href: "/onboarding/#{key.to_s.dasherize}?jwt=#{jwt}")
      end
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Onboarding::Whatsapp', type: :routing do
  describe 'GET /onboarding/whatsapp' do
    subject { { get: '/onboarding/whats-app' } }

    describe 'when no Whatsapp number was configured' do
      before { allow(Setting).to receive(:whats_app_configured?).and_return(false) }
      it { should_not be_routable }
    end

    describe 'when WhatsApp number is configured, but onboarding has been disallowed by an admin' do
      before do
        allow(Setting).to receive(:channels).and_return({ whats_app: { configured: true, allow_onboarding: false } })
      end

      it { is_expected.not_to be_routable }
    end

    describe 'but when a Whatsapp number is configured and onboarding has not been disallowed' do
      it { should be_routable }
    end
  end

  describe 'POST /onboarding/whatsapp' do
    subject { { post: '/onboarding/whats-app' } }

    describe 'when no Whatsapp number was configured' do
      before { allow(Setting).to receive(:whats_app_configured?).and_return(false) }
      it { should_not be_routable }
    end

    describe 'when WhatsApp number is configured, but onboarding has been disallowed by an admin' do
      before do
        allow(Setting).to receive(:channels).and_return({ whats_app: { configured: true, allow_onboarding: false } })
      end

      it { is_expected.not_to be_routable }
    end

    describe 'but when a Whatsapp number is configured and onboarding has not been disallowed' do
      it { should be_routable }
    end
  end
end

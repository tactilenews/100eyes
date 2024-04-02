# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Onboarding::Whatsapp', type: :routing do
  describe 'GET /onboarding/whatsapp' do
    subject { { get: '/onboarding/whats-app' } }

    describe 'when no Whatsapp number was configured' do
      before { allow(Setting).to receive(:whats_app_configured?).and_return(false) }
      it { should_not be_routable }
    end

    describe 'but when a Whatsapp number was configured' do
      before { allow(Setting).to receive(:whats_app_configured?).and_return(true) }
      it { should be_routable }
    end
  end

  describe 'POST /onboarding/whatsapp' do
    subject { { post: '/onboarding/whats-app' } }

    describe 'when no Whatsapp number was configured' do
      before { allow(Setting).to receive(:whats_app_configured?).and_return(false) }
      it { should_not be_routable }
    end

    describe 'but when a Whatsapp number was configured' do
      before { allow(Setting).to receive(:whats_app_configured?).and_return(true) }
      it { should be_routable }
    end
  end
end

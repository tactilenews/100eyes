# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Onboarding' do
  let(:jwt) { JsonWebToken.encode({ invite_code: 'ONBOARDING_TOKEN', action: 'onboarding' }) }

  describe 'visit /onboarding/' do
    describe 'if WhatsApp was explicitly activated or activated by configuration' do
      before { allow(Setting).to receive(:channels).and_return({ whats_app: true }) }
      it 'renders invitation link for WhatsApp' do
        visit onboarding_path(jwt: jwt)
        expect(page).to have_css('a', text: 'WhatsApp')
      end
    end

    describe 'but if WhatsApp is deactivated' do
      before { allow(Setting).to receive(:channels).and_return({ whats_app: false }) }
      it 'renders no invitation link for WhatsApp' do
        visit onboarding_path(jwt: jwt)
        expect(page).not_to have_css('a', text: 'WhatsApp')
      end
    end
  end
end

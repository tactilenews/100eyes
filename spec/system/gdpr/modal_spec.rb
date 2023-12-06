# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'GDPR modal' do
  let(:jwt) { JsonWebToken.encode({ invite_code: 'ONBOARDING_TOKEN', action: 'onboarding' }) }

  it 'visiting onboarding page' do
    visit onboarding_path(jwt: jwt)
    expect(page).not_to have_css('dialog.GdprModal')
  end

  describe 'If GDPR modal is enabled' do
    before { allow(Setting).to receive(:onboarding_show_gdpr_modal).and_return(true) }

    it 'visiting onboarding page' do
      visit onboarding_path(jwt: jwt)
      expect(page).to have_css('dialog.GdprModal')
    end
  end
end

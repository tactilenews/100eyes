# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'GDPR modal', type: :feature do
  let(:jwt) { JsonWebToken.encode({ invite_code: 'ONBOARDING_TOKEN', action: 'onboarding' }) }

  scenario 'visiting onboarding page' do
    visit onboarding_path(jwt: jwt)
    expect(page).not_to have_css('dialog.GdprModal')
  end

  context 'If GDPR modal is enabled' do
    before(:each) { allow(Setting).to receive(:onboarding_show_gdpr_modal).and_return(true) }

    scenario 'visiting onboarding page' do
      visit onboarding_path(jwt: jwt)
      expect(page).to have_css('dialog.GdprModal')
    end
  end
end

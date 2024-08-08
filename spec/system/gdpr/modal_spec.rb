# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'GDPR modal' do
  let(:organization) { create(:organization) }
  let(:jwt) { JsonWebToken.encode({ invite_code: 'ONBOARDING_TOKEN', action: 'onboarding', organization_id: organization.id }) }

  it 'visiting onboarding page' do
    visit organization_onboarding_path(organization, jwt: jwt)
    expect(page).not_to have_css('dialog.GdprModal')
  end

  describe 'If GDPR modal is enabled' do
    before(:each) { organization.update(onboarding_show_gdpr_modal: true) }

    it 'visiting onboarding page' do
      visit organization_onboarding_path(organization, jwt: jwt)
      expect(page).to have_css('dialog.GdprModal')
    end
  end
end

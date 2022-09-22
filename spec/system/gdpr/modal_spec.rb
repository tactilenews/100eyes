# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'GDPR modal' do
  let(:jwt) { JsonWebToken.encode({ invite_code: 'ONBOARDING_TOKEN', action: 'onboarding' }) }
  let(:onboarding_title_record) { Setting.new(var: :onboarding_title) }
  let(:onboarding_page_record) { Setting.new(var: :onboarding_page) }
  let(:onboarding_imprint_link_record) { Setting.new(var: :onboarding_imprint_link) }
  let(:onboarding_data_protection_link_record) { Setting.new(var: :onboarding_data_protection_link) }

  before do
    allow(Setting).to receive(:find_by).with(var: :onboarding_title).and_return(onboarding_title_record)
    allow(onboarding_title_record).to receive(:send).with("value_#{I18n.locale}".to_sym).and_return('This is 100eyes')
    allow(Setting).to receive(:find_by).with(var: :onboarding_page).and_return(onboarding_page_record)
    allow(onboarding_page_record).to receive(:send).with("value_#{I18n.locale}".to_sym).and_return('We are cool!')
    allow(Setting).to receive(:find_by).with(var: :onboarding_imprint_link).and_return(onboarding_imprint_link_record)
    allow(onboarding_imprint_link_record).to receive(:send).with("value_#{I18n.locale}".to_sym).and_return('https://example.org/imprint')
    allow(Setting).to receive(:find_by).with(var: :onboarding_data_protection_link).and_return(onboarding_data_protection_link_record)
    allow(onboarding_data_protection_link_record).to receive(:send).with("value_#{I18n.locale}".to_sym).and_return('https://example.org/privacy')
  end

  it 'visiting onboarding page' do
    visit onboarding_path(jwt: jwt)
    expect(page).not_to have_css('dialog.GdprModal')
  end

  describe 'If GDPR modal is enabled' do
    before(:each) { allow(Setting).to receive(:onboarding_show_gdpr_modal).and_return(true) }

    it 'visiting onboarding page' do
      visit onboarding_path(jwt: jwt)
      expect(page).to have_css('dialog.GdprModal')
    end
  end
end

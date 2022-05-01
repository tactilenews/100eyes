# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Setting', type: :feature do
  let(:user) { create(:user) }
  context 'upload a new onboarding header' do
    scenario 'visiting onboarding page' do
      expect(Setting.onboarding_hero).to be_blank

      visit settings_path(as: user)
      page.find('input[name="setting_files[onboarding_hero]"]').attach_file('example-image.png')
      click_on 'Speichern'

      expect(Setting.onboarding_hero).not_to be_blank
    end
  end
end

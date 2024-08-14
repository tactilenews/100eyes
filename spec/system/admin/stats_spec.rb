# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Stats' do
  context 'as admin' do
    let(:user) { create(:user, admin: true) }
    let(:mock_validator) { instance_double(ThreemaValidator) }

    before do
      create_list(:contributor, 3)
      create_list(:contributor, 2, :threema_contributor, :skip_validations)
      create_list(:contributor, 4, :telegram_contributor)
      create_list(:contributor, 2, :signal_contributor)
      create_list(:contributor, 4, :signal_contributor_uuid)
      create_list(:contributor, 12, :whats_app_contributor)
    end

    it 'admin edits contributor', flaky: true do
      visit admin_stats_path(as: user)

      expect(page).to have_content('Email contributors: 3')
      expect(page).to have_content('Threema contributors: 2')
      expect(page).to have_content('Telegram contributors: 4')
      expect(page).to have_content('Signal contributors: 6')
      expect(page).to have_content('WhatsApp contributors: 12')
    end
  end
end

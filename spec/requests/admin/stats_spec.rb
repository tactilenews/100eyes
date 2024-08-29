# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Stats' do
  context 'as admin' do
    subject { -> { get admin_stats_path(as: user) } }
    let(:user) { create(:user, admin: true) }
    let(:mock_validator) { instance_double(ThreemaValidator) }

    before do
      create_list(:contributor, 1)
      create_list(:contributor, 1, :threema_contributor, :skip_validations)
      create_list(:contributor, 2, :telegram_contributor)
      create_list(:contributor, 1, :signal_contributor)
      create_list(:contributor, 2, :signal_contributor_uuid)
      create_list(:contributor, 6, :whats_app_contributor)
      subject.call
    end

    it 'admin edits contributor', flaky: true do
      expect(page).to have_content('Email contributors: 1')
      expect(page).to have_content('Threema contributors: 1')
      expect(page).to have_content('Telegram contributors: 2')
      expect(page).to have_content('Signal contributors: 3')
      expect(page).to have_content('WhatsApp contributors: 6')
    end
  end
end

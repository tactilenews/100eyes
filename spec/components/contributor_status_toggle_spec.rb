# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContributorStatusToggle::ContributorStatusToggle, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:contributor) { create(:contributor, active: active) }
  let(:active) { true }
  let(:deactivated_by) { nil }
  let(:params) { { contributor: contributor, deactivated_by: deactivated_by } }

  it { is_expected.to have_css("form[action='/contributors/#{contributor.id}']") }

  context 'given an active contributor' do
    it { is_expected.to have_css('input[type="hidden"][value="off"]', visible: false) }
    it { is_expected.to have_css('h2', text: 'Mitglied deaktivieren') }
    it { is_expected.to have_css('strong', text: 'aktives Mitglied') }
    it { is_expected.to have_css('button', text: 'Mitglied deaktivieren') }
  end

  context 'given an inactive contributor' do
    let(:active) { false }

    it { is_expected.to have_css('input[type="hidden"][value="on"]', visible: false) }
    it { is_expected.to have_css('h2', text: 'Mitglied reaktivieren') }
    it { is_expected.to have_css('strong', text: 'inaktives Mitglied') }
    it { is_expected.to have_css('button', text: 'Mitglied reaktivieren') }

    context 'marked inactive by a user' do
      let(:deactivated_by) { create(:user) }

      before { contributor.update(deactivated_by_user_id: deactivated_by.id) }

      it { is_expected.to have_css('strong', text: deactivated_by.name) }
    end

    context 'through WhatsApp who requested to unsubscribe' do
      before { contributor.update(whats_app_phone_number: '+49151234567', email: nil, unsubscribed_at: 1.minute.ago) }

      it { is_expected.to have_css('strong', text: contributor.first_name) }
      it { is_expected.to have_content('hat darum gebeten, vom Erhalt von Nachrichten über WhatsApp abgemeldet zu werden.') }
    end
  end
end

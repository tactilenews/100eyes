# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContributorStatusToggle::ContributorStatusToggle, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:organization) { create(:organization) }
  let(:contributor) { create(:contributor, organization: organization) }
  let(:deactivated_by) { nil }
  let(:params) { { organization: organization, contributor: contributor, deactivated_by: deactivated_by } }

  it { should have_css("form[action='/#{contributor.organization_id}/contributors/#{contributor.id}']") }

  context 'given an active contributor' do
    it { should have_css('input[type="hidden"][value="off"]', visible: false) }
    it { should have_css('h2', text: 'Mitglied deaktivieren') }
    it { should have_css('strong', text: 'aktives Mitglied') }
    it { should have_css('button', text: 'Mitglied deaktivieren') }
  end

  context 'given an inactive contributor' do
    let!(:contributor) { create(:contributor, :inactive) }

    it { should have_css('input[type="hidden"][value="on"]', visible: false) }
    it { should have_css('h2', text: 'Mitglied reaktivieren') }
    it { should have_css('strong', text: 'inaktives Mitglied') }
    it { should have_css('button', text: 'Mitglied reaktivieren') }

    context 'marked inactive by a user' do
      let(:deactivated_by) { create(:user) }
      before { contributor.update(deactivated_by_user_id: deactivated_by.id) }

      it { should have_css('strong', text: deactivated_by.name) }
    end

    context 'marked inactive by an admin' do
      let(:deactivated_by) { create(:user, admin: true) }
      before { contributor.update(deactivated_by_user_id: deactivated_by.id, deactivated_by_admin: true) }

      it 'does not display admin name' do
        expect(subject).not_to have_css('strong', text: deactivated_by.name)
      end

      it "displays 'Admin' to make clear it was deactivated by and admin" do
        expect(subject).to have_css('strong', text: 'Admin')
      end
    end

    context 'through WhatsApp who requested to unsubscribe' do
      before { contributor.update(whats_app_phone_number: '+49151234567', email: nil, unsubscribed_at: 1.minute.ago) }

      it { should have_css('strong', text: contributor.first_name) }
      it { should have_content('hat darum gebeten, vom Erhalt von Nachrichten über WhatsApp abgemeldet zu werden.') }
    end
  end
end

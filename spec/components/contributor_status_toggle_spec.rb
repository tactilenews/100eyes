# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContributorStatusToggle::ContributorStatusToggle, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:contributor) { create(:contributor, active: active) }
  let(:active) { true }
  let(:params) { { contributor: contributor } }

  it { should have_css("form[action='/contributors/#{contributor.id}']") }

  context 'given an active contributor' do
    it { should have_css('input[type="hidden"][value="off"]', visible: false) }
    it { should have_css('h2', text: 'Mitglied deaktivieren') }
    it { should have_css('strong', text: 'aktives Mitglied') }
    it { should have_css('button', text: 'Mitglied deaktivieren') }
  end

  context 'given an inactive contributor' do
    let(:active) { false }

    it { should have_css('input[type="hidden"][value="on"]', visible: false) }
    it { should have_css('h2', text: 'Mitglied reaktivieren') }
    it { should have_css('strong', text: 'inaktives Mitglied') }
    it { should have_css('button', text: 'Mitglied reaktivieren') }
  end
end

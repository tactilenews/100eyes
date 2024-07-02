# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContributorHeader::ContributorHeader, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:organization) { create(:organization) }
  let(:contributor) { create(:contributor, created_at: '2021-01-01') }
  let(:params) { { organization: organization, contributor: contributor } }

  it { should have_css('header') }
  it { should have_css('h1', text: contributor.name) }
  it { should have_css('p', text: 'Mitglied seit 01.01.2021') }

  context 'given an inactive contributor' do
    let(:contributor) { create(:contributor, created_at: '2021-01-01', deactivated_at: '2021-02-01') }
    it { should have_css('p', text: 'Mitglied seit 01.01.2021') }
    it { should have_css('p', text: 'deaktiviert am 01.02.2021') }
  end

  it { should have_css("a[href='/contributors/#{contributor.id}/edit']", text: 'Stammdaten bearbeiten') }
  it { should have_css('button', text: 'Profilbild ändern') }
end

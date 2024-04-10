# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContributorHeader::ContributorHeader, type: :component do
  subject { render_inline(described_class.new(**params)) }

  let(:contributor) { create(:contributor, created_at: '2021-01-01') }
  let(:params) { { contributor: contributor } }

  it { is_expected.to have_css('header') }
  it { is_expected.to have_css('h1', text: contributor.name) }
  it { is_expected.to have_css('p', text: 'Mitglied seit 01.01.2021') }

  context 'given an inactive contributor' do
    let(:contributor) { create(:contributor, created_at: '2021-01-01', deactivated_at: '2021-02-01') }

    it { is_expected.to have_css('p', text: 'Mitglied seit 01.01.2021') }
    it { is_expected.to have_css('p', text: 'deaktiviert am 01.02.2021') }
  end

  it { is_expected.to have_css("a[href='/contributors/#{contributor.id}/edit']", text: 'Stammdaten bearbeiten') }
  it { is_expected.to have_css('button', text: 'Profilbild ändern') }
end

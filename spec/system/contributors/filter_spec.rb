# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Filter contributors' do
  let(:user) { create(:user) }
  let!(:active_contributor) { create(:contributor, active: true) }
  let!(:inactive_contributor) { create(:contributor, active: false) }
  let!(:another_contributor) { create(:contributor, active: true) }

  it 'Editor lists contributors' do
    visit contributors_path(as: user)

    expect(page).to have_link('Aktiv 2', href: contributors_path)
    expect(page).to have_link('Inaktiv 1', href: contributors_path(filter: :inactive))

    expect(page).to have_link(nil, href: contributor_path(active_contributor))
    expect(page).not_to have_link(nil, href: contributor_path(inactive_contributor))

    click_on 'Inaktiv'

    expect(page).to have_link(nil, href: contributor_path(inactive_contributor))
    expect(page).not_to have_link(nil, href: contributor_path(active_contributor))
  end

  it 'Editor views profile of an active contributor' do
    visit contributor_path(active_contributor, as: user)

    expect(page).to have_link(nil, href: contributor_path(active_contributor))
    expect(page).not_to have_link(nil, href: contributor_path(inactive_contributor))
  end

  it 'Editor views profile of an inactive contributor' do
    visit contributor_path(inactive_contributor, as: user)

    expect(page).to have_link(nil, href: contributor_path(active_contributor))
    expect(page).to have_link(nil, href: contributor_path(inactive_contributor))
  end
end

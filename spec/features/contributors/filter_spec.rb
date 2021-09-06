# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Filter contributors', type: :feature do
  let(:user) { create(:user) }
  let!(:active_contributor) { create(:contributor, active: true) }
  let!(:inactive_contributor) { create(:contributor, active: false) }
  let!(:another_contributor) { create(:contributor, active: true) }

  scenario 'Editor lists contributors' do
    visit contributors_path(as: user)

    expect(page).to have_link('Aktiv 2', href: contributors_path)
    expect(page).to have_link('Inaktiv 1', href: contributors_path(filter: :inactive))

    expect(page).to have_link(nil, href: contributor_path(active_contributor))
    expect(page).not_to have_link(nil, href: contributor_path(inactive_contributor))

    click_on 'Inaktiv'

    expect(page).to have_link(nil, href: contributor_path(inactive_contributor))
    expect(page).not_to have_link(nil, href: contributor_path(active_contributor))
  end

  scenario 'Editor views contributor profile' do
    visit contributor_path(active_contributor, as: user)

    expect(page).to have_link(nil, href: contributor_path(active_contributor))
    expect(page).not_to have_link(nil, href: contributor_path(inactive_contributor))
  end
end

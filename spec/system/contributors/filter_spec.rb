# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Filter contributors' do
  let(:user) { create(:user, organizations: [organization]) }
  let(:organization) { create(:organization) }
  let!(:active_contributor) { create(:contributor, tag_list: ['entwickler'], organization: organization) }
  let!(:inactive_contributor) { create(:contributor, :inactive, tag_list: ['entwickler'], organization: organization) }
  let!(:another_contributor) { create(:contributor, organization: organization) }

  it 'Editor lists contributors' do
    visit organization_contributors_path(organization, as: user)

    expect(page).to have_link('Aktiv 2', href: organization_contributors_path(organization, state: :active))
    expect(page).to have_link('Inaktiv 1', href: organization_contributors_path(organization, state: :inactive))

    expect(page).to have_link(nil, href: organization_contributor_path(organization, active_contributor))
    expect(page).not_to have_link(nil, href: organization_contributor_path(organization, inactive_contributor))

    click_on 'Inaktiv'

    expect(page).to have_link(nil, href: organization_contributor_path(organization, inactive_contributor))
    expect(page).not_to have_link(nil, href: organization_contributor_path(organization, active_contributor))

    click_on 'Aktiv'

    expect(page).not_to have_link(nil, href: organization_contributor_path(organization, inactive_contributor))
    expect(page).to have_link(nil, href: organization_contributor_path(organization, active_contributor))

    expect(page).not_to have_css('.ContributorsIndex-filterSection')
    click_on 'filtern'

    expect(page).to have_css('.ContributorsIndex-filterSection')
    find('.TagsInput').click
    within('.TagsInput-dropdown') do
      find('span', text: 'entwickler', match: :first).click
    end

    within('.ContributorsIndex-filterSection') do
      click_on 'filtern'
    end

    expect(page).to have_css('.ContributorsIndex-filterSection')
    expect(page).to have_content('Das sind die Mitglieder deiner Community gefiltert nach dem Tag (entwickler)')
    expect(page).to have_link('Aktiv 1', href: organization_contributors_path(organization, state: :active, tag_list: ['entwickler']))
    expect(page).to have_link(nil, href: organization_contributor_path(organization, active_contributor))
    expect(page).not_to have_link(nil, href: organization_contributor_path(organization, another_contributor))

    click_on 'zurücksetzen'

    expect(page).not_to have_css('.ContributorsIndex-filterSection')
    expect(page).not_to have_content('Das sind die Mitglieder deiner Community gefiltert nach dem Tag (entwickler)')
    expect(page).to have_link('Aktiv 2', href: organization_contributors_path(organization, state: :active))
    expect(page).to have_link(nil, href: organization_contributor_path(organization, active_contributor))
    expect(page).to have_link(nil, href: organization_contributor_path(organization, another_contributor))

    click_on 'filtern'

    expect(page).to have_css('.ContributorsIndex-filterSection')
    find('.TagsInput').click
    within('.TagsInput-dropdown') do
      find('span', text: 'entwickler', match: :first).click
    end

    within('.ContributorsIndex-filterSection') do
      click_on 'filtern'
    end

    click_on 'Inaktiv'

    expect(page).to have_css('.ContributorsIndex-filterSection')
    expect(page).to have_content('Das sind die Mitglieder deiner Community gefiltert nach dem Tag (entwickler)')
    expect(page).to have_link('Inaktiv 1', href: organization_contributors_path(organization, state: :inactive, tag_list: ['entwickler']))
    expect(page).to have_link(nil, href: organization_contributor_path(organization, inactive_contributor))

    within('.TabBar') do
      click_on 'filtern'
    end

    expect(page).not_to have_css('.ContributorsIndex-filterSection')
  end

  it 'Editor views profile of an active contributor' do
    visit organization_contributor_path(organization, active_contributor, as: user)

    expect(page).to have_link(nil, href: organization_contributor_path(organization, active_contributor))
    expect(page).not_to have_link(nil, href: organization_contributor_path(organization, inactive_contributor))
  end

  it 'Editor views profile of an inactive contributor' do
    visit organization_contributor_path(organization, inactive_contributor, as: user)

    expect(page).to have_link(nil, href: organization_contributor_path(organization, active_contributor))
    expect(page).to have_link(nil, href: organization_contributor_path(organization, inactive_contributor))
  end
end

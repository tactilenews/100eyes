# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Organizations' do
  let(:organizations) { create_list(:organization, 2) }
  let!(:other_organizations) { create_list(:organization, 2) }
  let(:admin) { create(:user, admin: true) }

  describe 'GET /organizations' do
    subject { -> { get organizations_path(as: user) } }

    context 'unauthenticated' do
      let(:user) { nil }

      it 'redirects to the sign in path' do
        subject.call
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context 'authenticated' do
      let(:user) { create(:user, organizations: organizations) }
      before { subject.call }

      it 'should be successful' do
        expect(response).to be_successful
      end

      it 'displays only the organizations the user belongs to' do
        expect(page).to have_css("a[href='#{organization_dashboard_path(organizations.first)}']", text: organizations.first.name)
        expect(page).to have_css("a[href='#{organization_dashboard_path(organizations.second)}']", text: organizations.second.name)
        expect(page).not_to have_css("a[href='#{organization_dashboard_path(other_organizations.first)}']",
                                     text: other_organizations.first.name)
        expect(page).not_to have_css("a[href='#{organization_dashboard_path(other_organizations.second)}']",
                                     text: other_organizations.second.name)
      end

      context 'user has admin privileges' do
        let(:user) { create(:user, admin: true) }

        it 'displays all organizations' do
          Organization.find_each do |organization|
            expect(page).to have_css("a[href='#{organization_dashboard_path(organization)}']", text: organization.name)
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '/dashboard' do
  let(:user) { create(:user, organizations: [organization]) }
  let(:organization) { create(:organization) }

  describe 'GET /index' do
    describe 'Permissions' do
      describe 'Not part of organization' do
        before { user.update(organizations: [create(:organization)]) }

        it 'should return not found' do
          get organization_dashboard_url(organization, as: user)
          expect(response).to have_http_status(:not_found)
        end
      end

      describe 'Part of organization' do
        it 'should be successful' do
          get organization_dashboard_url(organization, as: user)
          expect(response).to be_successful
        end
      end
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Organization management' do
  context 'POST /admin/organizations' do
    subject { -> { post admin_organizations_path(as: user), params: params } }

    let(:params) { { organization: { business_plan_id: create(:business_plan).id } } }
    context 'unauthenticated' do
      let(:user) { nil }

      it 'renders not found ' do
        subject.call
        expect(response).to be_not_found
      end
    end

    context 'unauthorized' do
      let(:user) { create(:user, admin: false) }

      it 'renders not found ' do
        subject.call
        expect(response).to be_not_found
      end
    end

    context 'authenticated and authorized' do
      let(:user) { create(:user, admin: true) }

      it 'creates the organization' do
        expect { subject.call }.to change(Organization, :count).from(0).to(1)
      end

      it "redirect to organization's show page" do
        subject.call
        expect(response).to redirect_to(admin_organization_path(Organization.last))
      end
    end
  end
end

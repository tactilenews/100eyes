# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'User management' do
  context 'PUT /admin/users/:id' do
    subject { -> { put admin_user_path(user, as: admin), params: params } }

    let(:organization) { create(:organization) }
    let!(:user) { create(:user, organizations: [organization]) }
    let(:admin) { create(:user, admin: true) }
    let(:another_organization) { create(:organization) }

    context 'adding an organization' do
      let(:params) { { user: { organization_ids: [organization.id, another_organization.id] } } }

      it "updates the user's organization" do
        expect { subject.call }.to (change { user.reload.organizations }).from([organization]).to([organization, another_organization])
      end
    end

    context 'removing an organization' do
      let(:params) { { user: { organization_ids: [organization.id] } } }

      before { user.update(organizations: [organization, another_organization]) }

      it "updates the user's organization" do
        expect { subject.call }.to (change { user.reload.organizations }).from([organization, another_organization]).to([organization])
      end
    end

    context 'Deactivating user' do
      let(:params) { { user: { active: false } } }

      it "updates the user's active status" do
        expect { subject.call }.to (change { user.reload.active? }).from(true).to(false)
      end
    end
  end
end

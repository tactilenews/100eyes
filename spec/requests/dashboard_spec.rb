# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '/{organization_id}/dashboard', type: :request do

  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  it_behaves_like "protected" do
    before { get organization_dashboard_path(organization, as: create(:user))}
  end

  it_behaves_like "unauthenticated" do
     before { get organization_dashboard_path(organization) }
  end
end

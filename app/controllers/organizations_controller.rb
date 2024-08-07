class OrganizationsController < ApplicationController
  def index
    redirect_to organization_dashboard_path(current_user.organization) if current_user.organization.present?

    @organizations = Organization.all
  end
end

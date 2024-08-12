# frozen_string_literal: true

class OrganizationsController < ApplicationController
  skip_before_action :set_organization
  layout 'minimal'

  def index
    redirect_to organization_dashboard_path(current_user.organization) if current_user.organization.present?

    @organizations = Organization.all
  end

  def set_organization
    organization = Organization.find(params[:organization_id])
    redirect_to organization_dashboard_path(organization)
  end
end

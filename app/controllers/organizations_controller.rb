# frozen_string_literal: true

class OrganizationsController < ApplicationController
  skip_before_action :set_organization
  layout 'minimal'

  def index
    # TODO: change this when having a organization habtm user relation
    redirect_to organization_dashboard_path(current_user.organization) if current_user.organization.present?

    @organizations = Organization.all
  end
end

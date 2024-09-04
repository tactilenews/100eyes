# frozen_string_literal: true

class OrganizationsController < ApplicationController
  skip_before_action :user_permitted?, :set_organization
  layout 'minimal'

  def index
    @organizations = current_user.admin? ? Organization.all : current_user.organizations
  end
end

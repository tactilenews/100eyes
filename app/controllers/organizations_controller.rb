# frozen_string_literal: true

class OrganizationsController < ApplicationController
  skip_before_action :user_permitted?, :set_organization
  layout 'minimal'

  def index
    @organizations = Organization.all
  end
end

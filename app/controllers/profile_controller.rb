# frozen_string_literal: true

class ProfileController < ApplicationController
  def index
    @current_business_plan = current_user.organization.business_plan
  end
end

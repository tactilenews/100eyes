# frozen_string_literal: true

class ProfileController < ApplicationController
  def index
    @organization = current_user.organization
  end
end

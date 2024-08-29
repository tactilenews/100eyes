# frozen_string_literal: true

class ErrorsController < ApplicationController
  layout 'minimal'

  skip_before_action :require_login, :user_permitted?, :set_organization

  def not_found
    render status: :not_found
  end

  def internal_server_error
    render status: :internal_server_error
  end
end

# frozen_string_literal: true

module Admin
  class ApplicationController < Administrate::ApplicationController
    include Authentication

    before_action :authorize_admin

    def authorize_admin
      head :forbidden unless current_user.admin?
    end
  end
end

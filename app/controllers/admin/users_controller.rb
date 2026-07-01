# frozen_string_literal: true

module Admin
  class UsersController < Administrate::ApplicationController
    def create
      user = User.new(resource_params)

      if user.save
        redirect_to admin_users_path(user), flash: { success: I18n.t('administrate.controller.create.success', resource: User.name) }
      else
        render :new, locals: {
          page: Administrate::Page::Form.new(dashboard, user)
        }, status: :unprocessable_entity
      end
    end
  end
end

# frozen_string_literal: true

module Admin
  class UsersController < Admin::ApplicationController
    def create
      user = User.new(resource_params)

      if user.save
        redirect_to admin_users_path(user), flash: { success: 'User was successfully created.' }
      else
        render :new, locals: {
          page: Administrate::Page::Form.new(dashboard, user)
        }, status: :unprocessable_entity
      end
    end

    def update
      user = User.find(update_params[:id])

      if user.update(update_params[:user])
        redirect_to admin_user_path(user), flash: { success: 'User was successfully updated.' }
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def resource_params
      params = super

      return params unless action_name == 'create'

      new_password = SecureRandom.alphanumeric(12)
      params.merge(password: new_password)
    end

    def update_params
      params.permit(:id, user: %i[first_name last_name email admin otp_enabled active])
    end
  end
end

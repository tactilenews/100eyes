# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :set_user, only: %i[update destroy show]

  def index
    @users = User.all
  end

  def show; end

  def update
    if @user.update(user_params)
      redirect_to user_url, flash: { success: I18n.t('contributor.saved', name: @user.name) }
    else
      render :edit
    end
  end

  def destroy
    @user.destroy
    redirect_to users_url, notice: 'User was successfully destroyed.'
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:note, :name, :email)
  end
end

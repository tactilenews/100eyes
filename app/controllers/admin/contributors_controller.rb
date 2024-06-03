# frozen_string_literal: true

module Admin
  class ContributorsController < Admin::ApplicationController
    include AdministrateExportable::Exporter

    before_action :set_contributor, only: :update
    before_action :toggle_active_state, only: :update

    def update
      if @contributor.update(update_params[:contributor])
        redirect_to admin_contributor_path(@contributor), flash: { success: 'Contributor was successfully updated.' }
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_contributor
      @contributor = Contributor.find(params[:id])
    end

    def update_params
      params.permit(:id,
                    contributor: %i[note first_name last_name])
    end

    def toggle_active_state
      return unless update_params[:contributor][:active]

      if ActiveModel::Type::Boolean.new.cast(update_params[:contributor][:active])
        @contributor.reactivate!
      else
        @contributor.deactivate!(user_id: current_user.id, admin: true)
      end
    end
  end
end

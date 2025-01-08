# frozen_string_literal: true

module Admin
  class ContributorsController < Administrate::ApplicationController
    include AdministrateExportable::Exporter

    before_action :set_contributor, only: :update

    def update
      toggle_active_state

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

    def toggle_active_state_params
      params.require(:contributor).permit(:active)
    end

    def toggle_active_state
      if ActiveModel::Type::Boolean.new.cast(toggle_active_state_params[:active])
        @contributor.reactivate!
      else
        @contributor.deactivate!(admin: true)
      end
    end
  end
end

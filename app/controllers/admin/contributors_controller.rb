# frozen_string_literal: true

module Admin
  class ContributorsController < Admin::ApplicationController
    include AdministrateExportable::Exporter

    def update
      contributor = Contributor.find(update_params[:id])
      contributor.deactivated_by_admin = !ActiveModel::Type::Boolean.new.cast(update_params[:contributor][:active])

      if contributor.update(update_params[:contributor])
        redirect_to admin_contributor_path(contributor), flash: { success: 'Contributor was successfully updated.' }
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def update_params
      params.permit(:id,
                    contributor: %i[note first_name last_name active])
    end
  end
end

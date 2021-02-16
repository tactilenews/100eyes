# frozen_string_literal: true

module Onboarding
  class ThreemaController < ChannelController
    private

    def contributor_params
      params.require(:contributor).permit(:first_name, :last_name, :threema_id)
    end

    def contributor_exists?
      Contributor.threema_id_taken?(contributor_params[:threema_id])
    end
  end
end

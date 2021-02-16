# frozen_string_literal: true

module Onboarding
  class EmailController < ChannelController
    private

    def contributor_params
      params.require(:contributor).permit(:first_name, :last_name, :email)
    end

    def contributor_exists?
      Contributor.email_taken?(contributor_params[:email])
    end
  end
end

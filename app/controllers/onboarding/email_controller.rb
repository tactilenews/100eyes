# frozen_string_literal: true

module Onboarding
  class EmailController < ChannelController
    private

    def redirect_to_failure
      # show validation errors
      render :show
    end

    def attr_name
      :email
    end
  end
end

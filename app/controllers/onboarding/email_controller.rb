# frozen_string_literal: true

module Onboarding
  class EmailController < ChannelController
    protected

    def redirect_to_failure
      # show validation errors
      render :show
    end

    private

    def attr_name
      :email
    end
  end
end

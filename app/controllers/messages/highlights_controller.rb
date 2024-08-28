# frozen_string_literal: true

module Messages
  class HighlightsController < ApplicationController
    before_action :set_message

    def update
      @message.update!(highlight_params)
      render json: { highlighted: @message.highlighted }
    end

    private

    def set_message
      # TODO: scope by organization
      @message = Message.find(params[:id])
    end

    def highlight_params
      params.permit(:highlighted)
    end
  end
end

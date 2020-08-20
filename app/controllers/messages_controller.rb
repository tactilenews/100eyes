# frozen_string_literal: true

class MessagesController < ApplicationController
  before_action :set_message, only: %i[highlight]

  def highlight
    @message.update!(message_params)
    render json: { highlighted: @message.highlighted }
  end

  private

  def set_message
    @message = Message.find(params[:id])
  end

  def message_params
    params.permit(:highlighted)
  end
end

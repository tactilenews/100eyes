# frozen_string_literal: true

class MessagesController < ApplicationController
  before_action :set_message

  def highlight
    @message.update!(highlight_params)
    render json: { highlighted: @message.highlighted }
  end

  def show_move_form; end

  def move
    previous_request = @message.request

    if @message.update(move_params)
      redirect_url = request_url(
        previous_request,
        moved_message: @message.id,
        anchor: "contributor-#{@message.contributor.id}"
      )

      return redirect_to(
        redirect_url,
        flash: { success: I18n.t('message.moved') }
      )
    end

    redirect_to(
      move_message_url,
      flash: { error: I18n.t('message.move_failed') }
    )
  end

  private

  def set_message
    @message = Message.find(params[:id])
  end

  def move_params
    params.require(:message).permit(:request_id)
  end

  def highlight_params
    params.permit(:highlighted)
  end
end

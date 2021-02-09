# frozen_string_literal: true

module Messages
  class RequestsController < ApplicationController
    before_action :set_message

    def show; end

    def update
      previous_request = @message.request

      if @message.update(message_params)
        anchor = "contributor-#{@message.contributor.id}"
        redirect_url = request_url(previous_request, anchor: anchor)

        flash[:success] = I18n.t('message.moved')
        redirect_to redirect_url
      else
        flash.now[:error] = I18n.t('message.move_failed')
        @message.restore_request_id!
        render :show
      end
    end

    private

    def set_message
      @message = Message.find(params[:id])
    end

    def message_params
      params.require(:message).permit(:request_id)
    end
  end
end

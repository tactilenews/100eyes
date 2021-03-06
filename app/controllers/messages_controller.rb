# frozen_string_literal: true

class MessagesController < ApplicationController
  before_action :set_request, :set_contributor

  def new; end

  def create
    @message = Message.new(text: params[:message][:text], sender: @contributor, request: @request, creator: current_user)
    @message.raw_data.attach(
      io: StringIO.new(params[:message][:text]),
      filename: 'manually_added.txt',
      content_type: 'text/plain'
    )
    if @message.save!
      redirect_to contributor_request_path(contributor_id: @contributor, id: @request), flash: { success: I18n.t('message.create.success') }
    else
      render :new_message, flash: { error: I18n.t('message.create.error') }
    end
  end

  private

  def set_request
    @request = Request.find(params[:request_id])
  end

  def set_contributor
    @contributor = Contributor.find(params[:contributor_id])
  end
end

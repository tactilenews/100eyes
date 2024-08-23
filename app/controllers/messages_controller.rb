# frozen_string_literal: true

class MessagesController < ApplicationController
  before_action :set_message, :only_allow_manually_created_messages, except: %i[new create]
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
      redirect_to @message.chat_message_link, flash: { success: I18n.t('message.create.success') }
    else
      render :new_message, flash: { error: I18n.t('message.create.error') }
    end
  end

  def edit; end

  def update
    if @message.update(text: params[:message][:text], creator: current_user)
      redirect_to @message.chat_message_link, flash: { success: I18n.t('message.edit.success') }
    else
      flash.now[:error] = I18n.t('message.edit.error')
      render :edit
    end
  end

  private

  def set_message
    @message = Message.find(params[:id])
  end

  def set_request
    request_id = params[:id] ? Message.find(params[:id]).request_id : params[:request_id]
    @request = Request.find(request_id)
  end

  def set_contributor
    contributor_id = params[:id] ? Message.find(params[:id]).sender_id : params[:contributor_id]
    @contributor = Contributor.find(contributor_id)
  end

  def only_allow_manually_created_messages
    return if @message.manually_created?

    flash[:error] = I18n.t('message.only_manually_created')
    redirect_back fallback_location: organization_dashboard_path(@organization)
  end
end

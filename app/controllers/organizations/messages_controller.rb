# frozen_string_literal: true

module Organizations
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
      @message = @organization.messages.find(params[:id])
    end

    def set_request
      @request = @message&.request || @organization.requests.find(params[:request_id])
    end

    def set_contributor
      @contributor = @message&.contributor || @organization.contributors.find(params[:contributor_id])
    end

    def only_allow_manually_created_messages
      return if @message.manually_created?

      flash[:error] = I18n.t('message.only_manually_created')
      redirect_back fallback_location: organization_dashboard_path(@organization)
    end
  end
end

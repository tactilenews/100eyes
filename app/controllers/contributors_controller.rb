# frozen_string_literal: true

class ContributorsController < ApplicationController
  before_action :set_contributor, only: %i[update destroy show edit message]
  before_action :count_params, only: :count

  def message
    request = contributor.active_request
    render(plain: 'No active request for this contributor', status: :bad_request) and return unless request

    text = message_params[:text]
    message = Message.create!(text: text, request: request, recipient: contributor, sender: nil)
    redirect_to message.chat_message_link, flash: { success: I18n.t('contributor.message-send', name: contributor.name) }
  end

  def index
    @active_count = Contributor.active.count
    @inactive_count = Contributor.inactive.count
    @contributors = ContributorDashboardService.call(params)
  end

  def show
    @contributors = Contributor
                    .active
                    .or(Contributor.where(id: @contributor.id))
                    .with_attached_avatar
  end

  def edit; end

  def update
    @contributors = Contributor.with_attached_avatar

    @contributor.editor_guarantees_data_consent = true

    if @contributor.update(contributor_params)
      redirect_to contributor_url, flash: { success: I18n.t('contributor.saved', name: @contributor.name) }
    else
      flash.now[:error] = I18n.t('contributor.invalid', name: @contributor.name)
      render :show, status: :unprocessable_entity
    end
  end

  def destroy
    @contributor.destroy
    redirect_to contributors_url, notice: 'Contributor was successfully destroyed.'
  end

  def count
    render json: { count: Contributor.with_tags(params[:tag_list]).count }
  end

  private

  def set_contributor
    @contributor = Contributor.find(params[:id])
  end

  def contributor_params
    params.require(:contributor).permit(:note, :first_name, :last_name, :avatar, :email, :threema_id, :phone, :zip_code, :city, :tag_list,
                                        :active, :additional_email)
  end

  def message_params
    params.require(:message).permit(:text)
  end

  def count_params
    params.permit(tag_list: [])
  end

  attr_reader :contributor
end

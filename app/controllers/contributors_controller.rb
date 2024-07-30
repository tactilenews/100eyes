# frozen_string_literal: true

class ContributorsController < ApplicationController
  before_action :set_contributor, only: %i[update destroy show edit message conversations]
  before_action :contributors_sidebar, only: %i[show update]
  before_action :count_params, only: :count
  before_action :contributors_params, only: :index

  def message
    request = if message_params[:reply_to_id].present?
                reply_to = contributor.replies.find(message_params[:reply_to_id])
                reply_to.request
              else
                contributor.active_request
              end
    render(plain: 'No active request for this contributor', status: :bad_request) and return unless request

    text = message_params[:text]
    message = Message.create!(text: text, request: request, recipient: contributor, sender: current_user)
    redirect_to message.chat_message_link, flash: { success: I18n.t('contributor.message-send', name: contributor.name) }
  end

  def index
    @state = state_params
    @tag_list = tag_list_params

    @active_count = Contributor.active.count
    @inactive_count = Contributor.inactive.count
    @unsubscribed_count = Contributor.unsubscribed.count
    @available_tags = @organization.contributors_tags_with_count.to_json

    @contributors = filtered_contributors
    @contributors = @contributors.with_tags(tag_list_params)
    @filter_count = @contributors.size
    @contributors = @contributors.with_attached_avatar.includes(:tags).page(contributors_params[:page])
  end

  def show; end

  def edit; end

  def update
    @contributor.editor_guarantees_data_consent = true
    toggle_active_state if toggle_active_state_params[:active]

    if @contributor.update(contributor_params)
      redirect_to contributor_url, flash: { success: I18n.t('contributor.saved', name: @contributor.name) }
    else
      handle_failed_update

      render :show, status: :unprocessable_entity
    end
  end

  def destroy
    @contributor.destroy
    redirect_to contributors_url, notice: I18n.t('contributor.destroyed', name: @contributor.name)
  end

  def count
    render json: { count: Contributor.with_tags(params[:tag_list]).count }
  end

  def conversations
    @messages = @contributor.conversations.includes(%i[files photos request recipient sender])
    @reply_to = @contributor.replies.find(params[:reply_to]) if params[:reply_to].present?
  end

  private

  def set_contributor
    @contributor = Contributor.find(params[:id])
  end

  def contributors_sidebar
    @contributors_sidebar ||= Contributor
                              .active
                              .or(Contributor.where(id: @contributor.id))
                              .with_attached_avatar
  end

  def toggle_active_state
    if ActiveModel::Type::Boolean.new.cast(toggle_active_state_params[:active])
      @contributor.reactivate!
    else
      @contributor.deactivate!(user_id: current_user.id)
    end
  end

  def contributors_params
    params.permit(:state, :page, tag_list: [])
  end

  def contributor_params
    params.require(:contributor).permit(:note, :first_name, :last_name, :avatar, :email, :threema_id, :phone, :zip_code, :city, :tag_list,
                                        :additional_email)
  end

  def toggle_active_state_params
    params.require(:contributor).permit(:active)
  end

  def message_params
    params.require(:message).permit(:text, :reply_to_id)
  end

  def count_params
    params.permit(tag_list: [])
  end

  def state_params
    value = contributors_params[:state]&.to_sym

    return :active unless %i[active inactive unsubscribed].include?(value)

    value
  end

  def filtered_contributors
    case @state
    when :inactive
      Contributor.inactive
    when :unsubscribed
      Contributor.unsubscribed
    else
      Contributor.active
    end
  end

  def tag_list_params
    value = contributors_params[:tag_list]
    return [] if value.blank? || value.all?(&:blank?)

    value.reject(&:empty?).first.split(',')
  end

  def handle_failed_update
    flash.now[:error] = I18n.t('contributor.invalid', name: contributor.name)

    return if contributor.errors[:avatar].blank?

    # Reset the avatar attachment to it's previous, valid state,
    # as displaying an invalid avatar will result in rendering errors.
    old_avatar = Contributor.with_attached_avatar.find(@contributor.id).avatar
    contributor.avatar = old_avatar.blob
  end

  attr_reader :contributor
end

# frozen_string_literal: true

class OnboardingController < ApplicationController
  skip_before_action :require_login, :user_permitted?
  before_action :ensure_onboarding_allowed
  before_action :verify_jwt, except: :success
  before_action :resume_telegram_onboarding, only: %i[index show]
  before_action :resume_signal_onboarding, only: %i[index show]
  before_action :redirect_if_contributor_exists, only: :create

  rescue_from ActionController::BadRequest, with: :render_unauthorized
  rescue_from JWT::DecodeError, with: :render_unauthorized

  layout 'onboarding'

  def index
    @jwt = jwt_param
    @channels = @organization.channels_onboarding_allowed
  end

  def success; end

  def show
    @contributor = Contributor.new
  end

  def create
    @contributor = Contributor.new(contributor_params.merge(json_web_token_attributes: { invalidated_jwt: jwt_param },
                                                            organization: @organization))
    @contributor.tag_list = tag_list_from_jwt

    if @contributor.save
      @contributor.send_welcome_message!
      redirect_to_success
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def attr_value
    contributor_params[attr_name]
  end

  def contributor_params
    params.require(:contributor).permit(:first_name, :last_name, :data_processing_consent, :additional_consent, attr_name)
  end

  def redirect_if_contributor_exists
    # We handle an onboarding request for a contributor that
    # already exists in the exact same way as a successful
    # onboarding so that we don't disclose whether someone
    # is a contributor.

    return unless contributor_exists?

    JsonWebToken.create(invalidated_jwt: jwt_param)
    redirect_to_success
  end

  def contributor_exists?
    # Instead of checking just for uniqueness
    # we do a full record validation and check
    # for the presence of the `taken` error. This
    # is necessary as custom validators may perform
    # additional normalization.
    contributor = Contributor.new(attr_name => attr_value, :organization => @organization)
    contributor.valid?

    contributor.errors.details[attr_name].pluck(:error).include?(:taken)
  end

  def default_url_options
    super.merge(jwt: params[:jwt])
  end

  def redirect_to_success
    redirect_to organization_onboarding_success_path(@organization, jwt: nil)
  end

  def render_unauthorized
    render 'onboarding/unauthorized', status: :unauthorized
  end

  def verify_jwt
    return unless jwt

    raise ActionController::BadRequest unless resume_telegram_onboarding? || resume_signal_onboarding?
  end

  def resume_telegram_onboarding
    return unless resume_telegram_onboarding?

    token = jwt.contributor.telegram_onboarding_token
    redirect_to organization_onboarding_telegram_link_path(@organization, telegram_onboarding_token: token)
  end

  def resume_telegram_onboarding?
    contributor = jwt&.contributor
    contributor&.telegram_id.blank? && contributor&.telegram_onboarding_token.present?
  end

  def resume_signal_onboarding
    return unless resume_signal_onboarding?

    token = jwt.contributor.signal_onboarding_token
    redirect_to organization_onboarding_signal_link_path(@organization, signal_onboarding_token: token)
  end

  def resume_signal_onboarding?
    contributor = jwt&.contributor
    contributor&.signal_uuid.blank? && contributor&.signal_onboarding_token.present?
  end

  def jwt
    decoded_token = JsonWebToken.decode(jwt_param)
    action = decoded_token.first['data']['action']

    raise ActionController::BadRequest if action != 'onboarding'

    JsonWebToken.includes(:contributor).find_by(invalidated_jwt: jwt_param)
  end

  def tag_list_from_jwt
    decoded_token = JsonWebToken.decode(jwt_param)
    decoded_token.first['data']['tag_list']
  end

  def jwt_param
    params.require(:jwt)
  end

  def onboarding_allowed?
    @organization.channels_onboarding_allowed.present?
  end

  def ensure_onboarding_allowed
    raise ActionController::RoutingError, 'Not Found' unless onboarding_allowed?
  end
end

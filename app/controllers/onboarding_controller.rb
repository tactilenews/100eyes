# frozen_string_literal: true

class OnboardingController < ApplicationController
  include Locale

  skip_before_action :require_login
  before_action :verify_jwt, except: :success
  before_action :resume_telegram_onboarding, only: %i[index show]
  before_action :redirect_if_contributor_exists, only: :create

  rescue_from ActionController::BadRequest, with: :render_unauthorized
  rescue_from JWT::DecodeError, with: :render_unauthorized

  layout 'onboarding'

  def index
    @jwt = jwt_param
  end

  def success; end

  def show
    @contributor = Contributor.new
  end

  def create
    @contributor = Contributor.new(contributor_params.merge(json_web_token_attributes: { invalidated_jwt: jwt_param },
                                                            tag_list: I18n.locale.to_s))

    if @contributor.save
      complete_onboarding(@contributor)
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
    contributor = Contributor.new(attr_name => attr_value)
    contributor.valid?

    contributor.errors.details[attr_name].pluck(:error).include?(:taken)
  end

  def default_url_options
    super.merge(jwt: params[:jwt])
  end

  def redirect_to_success
    redirect_to onboarding_success_path(jwt: nil)
  end

  def render_unauthorized
    render 'onboarding/unauthorized', status: :unauthorized
  end

  def verify_jwt
    return unless jwt
    raise ActionController::BadRequest unless resume_telegram_onboarding?
  end

  def complete_onboarding(contributor); end

  def resume_telegram_onboarding
    return unless resume_telegram_onboarding?

    token = jwt.contributor.telegram_onboarding_token
    redirect_to onboarding_telegram_link_path(telegram_onboarding_token: token)
  end

  def resume_telegram_onboarding?
    contributor = jwt&.contributor
    contributor&.telegram_id.blank? && contributor&.telegram_onboarding_token.present?
  end

  def jwt
    decoded_token = JsonWebToken.decode(jwt_param)
    action = decoded_token.first['data']['action']

    raise ActionController::BadRequest if action != 'onboarding'

    JsonWebToken.includes(:contributor).find_by(invalidated_jwt: jwt_param)
  end

  def jwt_param
    params.require(:jwt)
  end
end

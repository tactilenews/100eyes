# frozen_string_literal: true

class OnboardingController < ApplicationController
  skip_before_action :require_login
  before_action :verify_onboarding_params, except: :success
  before_action :redirect_if_contributor_exists, only: :create
  layout 'onboarding'

  def index
    @jwt = jwt_param
  end

  def success; end

  def show
    @contributor = Contributor.new
  end

  def create
    @contributor = Contributor.new(contributor_params.merge(json_web_token_attributes: { invalidated_jwt: jwt_param }))

    if @contributor.save
      redirect_to_success
    else
      redirect_to_failure
    end
  end

  private

  def redirect_to_failure
    # show validation errors
    render :show
  end

  def redirect_if_contributor_exists
    # We handle an onbaording request for a contributor that
    # already exists in the exact same way as a successful
    # onboarding so that we don't disclose wether someone
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

  def attr_value
    contributor_params[attr_name]
  end

  def contributor_params
    params.require(:contributor).permit(:first_name, :last_name, :data_processing_consent, attr_name)
  end

  def default_url_options
    super.merge(jwt: jwt_param)
  end

  def redirect_to_success
    redirect_to onboarding_success_path(jwt: nil)
  end

  def jwt_param
    params.require(:jwt)
  end

  def verify_onboarding_params
    decoded_token = JsonWebToken.decode(jwt_param)
    raise ActionController::BadRequest if decoded_token.first['data']['action'] != 'onboarding'

    json_web_token = JsonWebToken.includes(:contributor).find_by(invalidated_jwt: jwt_param)
    return unless json_web_token

    contributor = json_web_token.contributor
    if contributor && contributor.telegram_id.blank? && contributor.telegram_onboarding_token.present?
      return if %w[link fallback].include? action_name

      redirect_to onboarding_telegram_link_path(telegram_onboarding_token: contributor.telegram_onboarding_token) and return
    end
    raise ActionController::BadRequest
  rescue ActionController::BadRequest, JWT::DecodeError
    render 'onboarding/unauthorized', status: :unauthorized
  end
end

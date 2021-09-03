# frozen_string_literal: true

class BackDoor < Clearance::BackDoor
  private

  def sign_in_through_the_back_door(env)
    # The parent class works by intercepting requests and checking
    # for the `as` parameter. If it exists, it signs in the respective
    # user. Only if that's the case we set the `otp_verified_for_user`
    # session variable.

    # We need to parse the query before calling `super`, as the parent
    # method removes the `as` parameter from the query.
    params = Rack::Utils.parse_query(env['QUERY_STRING'])
    user_param = params['as']

    super

    return if user_param.blank?

    user = env[:clearance].current_user
    request = Rack::Request.new(env)
    request.session[:otp_verified_for_user] = user.id
  end
end

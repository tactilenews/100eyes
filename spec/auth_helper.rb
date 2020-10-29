# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:each) do
    def auth_headers
      header = ActionController::HttpAuthentication::Basic.encode_credentials(
        Setting.basic_auth_login_user,
        Setting.basic_auth_login_password
      )

      { HTTP_AUTHORIZATION: header }
    end
  end
end

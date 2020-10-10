# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:each) do
    login = { user: 'user', password: 'password' }
    allow(Rails.application.credentials).to receive(:login).and_return(login)

    def auth_headers
      header = ActionController::HttpAuthentication::Basic.encode_credentials(
        ENV['BASIC_AUTH_LOGIN_USER'],
        ENV['BASIC_AUTH_LOGIN_PASSWORD']
      )

      { HTTP_AUTHORIZATION: header }
    end
  end
end

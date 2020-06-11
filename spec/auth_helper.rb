# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:each) do
    login = { user: 'user', password: 'password' }
    allow(Rails.application.credentials).to receive(:login).and_return(login)

    def auth_headers
      header = ActionController::HttpAuthentication::Basic.encode_credentials(
        Rails.application.credentials.login.dig(:user),
        Rails.application.credentials.login.dig(:password)
      )

      { HTTP_AUTHORIZATION: header }
    end
  end
end

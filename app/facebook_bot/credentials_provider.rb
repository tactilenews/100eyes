# frozen_string_literal: true

class CredentialsProvider < Facebook::Messenger::Configuration::Providers::Base
  def valid_verify_token?(verify_token)
    verify_token == Rails.application.credentials.dig(:facebook, :verify_token)
  end

  # Return String of app secret of Facebook App.
  # Make sure you are returning the app secret if you overwrite
  # configuration provider class as this app secret is used to
  # validate the incoming requests.
  def app_secret_for(*)
    Rails.application.credentials.dig(:facebook, :app_secret)
  end

  # Return String of page access token.
  def access_token_for(*)
    Rails.application.credentials.dig(:facebook, :access_token)
  end
end

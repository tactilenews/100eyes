# frozen_string_literal: true

module OtpSetup
  class Component < ApplicationComponent
    def initialize(user:, **)
      super

      @user = user
    end

    private

    attr_reader :user

    def provisioning_url
      user.provisioning_uri(nil, issuer: Setting.application_host)
    end
  end
end

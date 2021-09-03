# frozen_string_literal: true

module OtpSetup
  class OtpSetup < ApplicationComponent
    def initialize(user:, **)
      super

      @user = user
    end

    private

    attr_reader :user
  end
end

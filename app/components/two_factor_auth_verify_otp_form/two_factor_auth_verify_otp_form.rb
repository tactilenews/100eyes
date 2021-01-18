# frozen_string_literal: true

module TwoFactorAuthVerifyOtpForm
  class TwoFactorAuthVerifyOtpForm < ApplicationComponent
    def initialize(user: nil)
      super

      @user = user
    end

    private

    attr_reader :user
  end
end

# frozen_string_literal: true

module SignalCaptchaForm
  class SignalCaptchaForm < ApplicationComponent
    def initialize(organization:)
      super

      @organization = organization
    end

    attr_reader :organization
  end
end

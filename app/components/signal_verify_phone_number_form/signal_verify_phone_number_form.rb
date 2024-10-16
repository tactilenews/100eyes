# frozen_string_literal: true

module SignalVerifyPhoneNumberForm
  class SignalVerifyPhoneNumberForm < ApplicationComponent
    def initialize(organization:)
      super

      @organization = organization
    end

    attr_reader :organization
  end
end

# frozen_string_literal: true

module SignInForm
  class SignInForm < ApplicationComponent
    def initialize
      super

      @resource = User.new
    end

    private

    attr_reader :resource
  end
end

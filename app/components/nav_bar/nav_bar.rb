# frozen_string_literal: true

module NavBar
  class NavBar < ApplicationComponent
    def initialize(current_user:, organization:, **)
      super

      @current_user = current_user
      @organization = organization
    end

    private

    attr_reader :current_user, :organization
  end
end

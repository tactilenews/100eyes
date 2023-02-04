# frozen_string_literal: true

module UserManagement
  class UserManagement < ApplicationComponent
    def initialize(organization:, **)
      super

      @organization = organization
    end

    attr_reader :organization
  end
end

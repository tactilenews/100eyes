# frozen_string_literal: true

module CreateUserModal
  class CreateUserModal < ApplicationComponent
    def initialize(organization:, **)
      super

      @organization = organization
    end

    attr_reader :organization
  end
end

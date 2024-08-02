# frozen_string_literal: true

module OrganizationComponents
  class Base < ApplicationComponent
    def initialize(organization:, **)
      @organization = organization

      super
    end

    attr_reader :organization
  end
end

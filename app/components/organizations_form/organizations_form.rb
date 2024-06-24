# frozen_string_literal: true

module OrganizationsForm
  class OrganizationsForm < ApplicationComponent
    def initialize(organization:)
      super

      @organization = organization
    end

    attr_reader :organization
  end
end

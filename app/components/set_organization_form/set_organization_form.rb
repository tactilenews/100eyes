# frozen_string_literal: true

module SetOrganizationForm
  class SetOrganizationForm < ApplicationComponent
    def initialize(organizations:)
      super

      @organizations = organizations
    end

    attr_reader :organizations
  end
end

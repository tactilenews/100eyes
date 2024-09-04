# frozen_string_literal: true

module OrganizationsIndex
  class OrganizationsIndex < ApplicationComponent
    def initialize(current_user:, organizations:)
      super

      @current_user = current_user
      @organizations = organizations
    end

    attr_reader :current_user, :organizations
  end
end

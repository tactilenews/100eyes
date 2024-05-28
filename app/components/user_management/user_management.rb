# frozen_string_literal: true

module UserManagement
  class UserManagement < ApplicationComponent
    def initialize(organization:, **)
      super

      @organization = organization
    end

    attr_reader :organization

    def active_non_admin_users
      organization.users.active.reject(&:admin?)
    end
  end
end

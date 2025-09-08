# frozen_string_literal: true

module NavBar
  class NavBar < ApplicationComponent
    def initialize(organization:, current_user:, **)
      super

      @organization = organization
      @current_user = current_user
    end

    private

    attr_reader :current_user, :organization

    def enterprise_instance?
      ActiveModel::Type::Boolean.new.cast(ENV.fetch('IS_ENTERPRISE_INSTANCE', 'false'))
    end
  end
end

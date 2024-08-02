# frozen_string_literal: true

module NavBar
  class NavBar < OrganizationComponent
    def initialize(current_user:, **)
      super

      @current_user = current_user
    end

    private

    attr_reader :current_user
  end
end

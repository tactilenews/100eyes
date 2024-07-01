# frozen_string_literal: true

module SettingsForm
  class SettingsForm < ApplicationComponent
    def initialize(organization:, current_user:)
      super

      @organization = organization
      @current_user = current_user
    end

    attr_reader :organization, :current_user
  end
end

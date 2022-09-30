# frozen_string_literal: true

module SettingsForm
  class SettingsForm < ApplicationComponent
    def initialize(current_user:)
      super

      @current_user = current_user
    end

    attr_reader :current_user
  end
end

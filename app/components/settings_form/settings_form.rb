# frozen_string_literal: true

module SettingsForm
  class SettingsForm < ApplicationComponent
    def initialize
      @setting = Setting.new
    end

    private

    attr_reader :setting
  end
end

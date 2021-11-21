# frozen_string_literal: true

module SettingsForm
  class Component < ApplicationComponent
    def initialize
      super

      @setting = Setting.new
    end

    private

    attr_reader :setting
  end
end

# frozen_string_literal: true

module SettingForm
  class SettingForm < ApplicationComponent
    def initialize
      @setting = Setting.new
    end

    private

    attr_reader :setting
  end
end

# frozen_string_literal: true

module SettingsField
  class SettingsField < ApplicationComponent
    def initialize(type:, setting:, **)
      super

      @type = type
      @setting = setting
    end

    def call
      component('field', object: Setting.new, value: Setting.send(setting), attr: setting) do |field|
        component(type, field.input_defaults)
      end
    end

    private

    attr_reader :type, :setting
  end
end

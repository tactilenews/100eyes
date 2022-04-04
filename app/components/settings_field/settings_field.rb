# frozen_string_literal: true

module SettingsField
  class SettingsField < ApplicationComponent
    def initialize(type:, attr:, **)
      super

      @type = type
      @attr = attr
    end

    def call
      component('field', object: Setting.new, value: Setting.send(attr), attr: attr) do |field|
        component(type, field.input_defaults)
      end
    end

    private

    attr_reader :type, :attr
  end
end

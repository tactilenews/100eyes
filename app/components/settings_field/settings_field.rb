# frozen_string_literal: true

module SettingsField
  class SettingsField < ApplicationComponent
    def initialize(type:, attr:, locale: nil, **)
      super

      @type = type
      @attr = attr
      @locale = locale
    end

    def call
      value = locale ? "value_#{locale}" : 'value'
      component('field', object: Setting.new, value: Setting.find_by(var: attr)&.send(value.to_sym), attr: attr, locale: locale) do |field|
        component(type, field.input_defaults)
      end
    end

    private

    attr_reader :type, :attr, :locale, :id
  end
end

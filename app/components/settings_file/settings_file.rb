# frozen_string_literal: true

module SettingsFile
  class SettingsFile < ApplicationComponent
    def initialize(attr:, **)
      super

      @attr = attr
    end

    def call
      id = "setting_files[#{attr}]"
      help = I18n.t("setting.form.#{attr}.help", default: nil)
      label = I18n.t("setting.form.#{attr}.label", default: nil)
      component('base_field', id: id, label: label, help: help) do |_field|
        component('input', type: :file, id: id)
      end
    end

    private

    attr_reader :type, :attr
  end
end

# frozen_string_literal: true

module Field
  class Field < ApplicationComponent
    def initialize(object:, attr:, help_md: nil, value: nil, **)
      super

      @object = object
      @attr = attr
      @value = value
      @help_md = help_md
    end

    def call
      c('base_field', {
          id: id,
          label: label,
          help: help,
          help_md: help_md,
          errors: errors,
          styles: styles,
          **attrs
        }) do
        content
      end
    end

    def input_defaults
      {
        id: id,
        value: value,
        placeholder: placeholder,
        styles: errors.any? ? [:error] : []
      }
    end

    private

    attr_reader :object, :attr, :help_md

    def id
      "#{model_name}[#{attr}]"
    end

    def model_name
      object.model_name.name.underscore
    end

    def value
      @value ||= object.send(attr)
    end

    def label
      I18n.t("#{model_name}.form.#{attr}.label")
    end

    def help
      # rubocop:disable Rails/OutputSafety
      I18n.t("#{model_name}.form.#{attr}.help", default: nil)&.html_safe
      # rubocop:enable Rails/OutputSafety
    end

    def placeholder
      I18n.t("#{model_name}.form.#{attr}.placeholder", default: nil)
    end

    def errors
      object.errors[attr]
    end
  end
end

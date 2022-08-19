# frozen_string_literal: true

module Field
  class Field < ApplicationComponent
    def initialize(object:, attr:, value: nil, locale: nil, **)
      super

      @object = object
      @attr = attr
      @value = value
      @locale = locale
    end

    def call
      c('base_field', {
          id: id,
          label: label,
          help: help,
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

    attr_reader :object, :attr, :locale

    def id
      id = "#{model_name}[#{attr}]"
      locale ? "#{id}[value_#{locale}]" : id
    end

    def model_name
      object.model_name.name.underscore
    end

    def value
      @value ||= object.send(attr)
    end

    def label
      key = locale ? "label_#{locale}" : 'label'
      I18n.t("#{model_name}.form.#{attr}.#{key}")
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

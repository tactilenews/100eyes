# frozen_string_literal: true

module Field
  class Field < ApplicationComponent
    def initialize(object:, id:, value: nil, **)
      super
      @object = object
      @id = id
      @value = value
    end

    def checkbox_defaults
      basic_defaults
    end

    def input_defaults
      basic_defaults
        .merge({
                 placeholder: I18n.t("#{type}.form.#{id}.placeholder", value: value, default: nil),
                 title: I18n.t("#{type}.form.#{id}.title", value: value, default: nil),
                 styles: [:small]
               })
    end

    private

    attr_reader :object, :id

    def validation_errors
      object.errors[id]
    end

    def label
      I18n.t("#{type}.form.#{id}.label")
    end

    def help
      # rubocop:disable Rails/OutputSafety
      I18n.t("#{type}.form.#{id}.help", value: value, default: nil)&.html_safe
      # rubocop:enable Rails/OutputSafety
    end

    def basic_defaults
      {
        value: value,
        id: "#{type}[#{id}]"
      }
    end

    def type
      object.model_name.name.underscore
    end

    def value
      @value ||= object.send(id)
    end
  end
end

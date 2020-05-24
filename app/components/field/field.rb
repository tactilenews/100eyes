# frozen_string_literal: true

module Field
  class Field < ApplicationComponent
    def initialize(object:, id:, help: nil, **)
      super
      @object = object
      @id = id
      @help = help
    end

    def checkbox_defaults
      basic_defaults
    end

    def input_defaults
      basic_defaults
        .merge({
                 placeholder: I18n.t("#{type}.form.#{id}.placeholder", value: value),
                 title: I18n.t("#{type}.form.#{id}.title", value: value, default: nil),
                 styles: [:small]
               })
    end

    private

    def validation_errors
      object.errors[id]
    end

    def label
      I18n.t("#{type}.form.#{id}.label")
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
      object.send(id)
    end

    attr_reader :object, :id, :content, :help
  end
end

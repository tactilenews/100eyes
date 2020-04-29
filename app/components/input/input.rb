# frozen_string_literal: true

module Input
  class Input < ApplicationComponent
    def initialize(id: nil, value: nil, placeholder: nil, required: false, type: 'text', styles: [])
      super(styles: styles)

      @id = id
      @value = value
      @placeholder = placeholder
      @required = required
      @type = type
    end

    def call
      content_tag(
        :input,
        nil,
        id: id,
        name: id,
        value: value,
        class: class_names,
        required: required,
        placeholder: placeholder
      )
    end

    attr_reader :id, :value, :placeholder, :required, :type
  end
end

# frozen_string_literal: true

module Textarea
  class Textarea < ApplicationComponent
    def initialize(id: nil, value: nil, placeholder: nil, required: false, styles: [])
      super(styles: styles)

      @id = id
      @value = value
      @placeholder = placeholder
      @required = required
    end

    def call
      content_tag(
        :textarea,
        value,
        id: id,
        name: id,
        class: class_names,
        data: {
          controller: 'textarea',
          action: 'input->textarea#resize'
        },
        required: required,
        placeholder: placeholder
      )
    end

    private

    attr_reader :id, :value, :placeholder, :required
  end
end

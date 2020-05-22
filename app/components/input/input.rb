# frozen_string_literal: true

module Input
  class Input < ApplicationComponent
    def initialize(id: nil, value: nil, placeholder: nil, required: false, disabled: false, type: 'text', stimulus_target: nil, **)
      super

      @id = id
      @type = type
      @value = value
      @placeholder = placeholder
      @required = required
      @disabled = disabled
      @stimulus_target = stimulus_target
    end

    def call
      content_tag(
        :input,
        nil,
        id: id,
        type: type,
        name: id,
        value: value,
        class: class_names,
        required: required,
        disabled: disabled,
        placeholder: placeholder,
        data: {
          target: stimulus_target
        }
      )
    end

    private

    attr_reader :id, :type, :value, :placeholder, :required, :disabled, :stimulus_target
  end
end

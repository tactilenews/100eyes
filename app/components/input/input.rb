# frozen_string_literal: true

module Input
  class Input < ApplicationComponent
    def initialize(id: nil, value: nil, placeholder: nil, title: nil, required: false, disabled: false, type: 'text', stimulus_target: nil, **)
      super

      @id = id
      @type = type
      @value = value
      @placeholder = placeholder
      @title = title
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
        title: title,
        data: {
          target: stimulus_target
        }
      )
    end

    private

    attr_reader :id, :type, :value, :placeholder, :title, :required, :disabled, :stimulus_target
  end
end

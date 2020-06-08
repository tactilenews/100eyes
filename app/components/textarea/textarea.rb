# frozen_string_literal: true

module Textarea
  class Textarea < ApplicationComponent
    def initialize(id: nil, value: nil, placeholder: nil, required: false, stimulus_target: nil, **)
      super

      @id = id
      @value = value
      @placeholder = placeholder
      @required = required
      @stimulus_target = stimulus_target
    end

    def call
      tag.textarea(
        value,
        id: id,
        name: id,
        required: required,
        placeholder: placeholder,
        class: class_names,
        data: {
          controller: 'textarea',
          action: 'input->textarea#resize',
          target: stimulus_target
        }
      )
    end

    private

    attr_reader :id, :value, :placeholder, :required, :stimulus_target
  end
end

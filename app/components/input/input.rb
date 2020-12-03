# frozen_string_literal: true

# rubocop:disable Metrics/ParameterLists

module Input
  class Input < ApplicationComponent
    def initialize(id: nil,
                   value: nil,
                   placeholder: nil,
                   title: nil,
                   required: false,
                   disabled: false,
                   type: 'text',
                   stimulus_target: nil,
                   stimulus_action: nil,
                   icon: nil,
                   **)
      super

      @id = id
      @type = type
      @value = value
      @placeholder = placeholder
      @title = title
      @required = required
      @disabled = disabled
      @stimulus_target = stimulus_target
      @stimulus_action = stimulus_action
      @icon = icon
      styles << :icon if icon
    end

    def input_tag
      tag.input(
        nil,
        id: id,
        type: type,
        name: id,
        value: value,
        required: required,
        disabled: disabled,
        placeholder: placeholder,
        title: title,
        data: {
          target: stimulus_target,
          action: stimulus_action
        }
      )
    end

    private

    attr_reader :id, :type, :value, :placeholder, :title, :required, :disabled, :stimulus_target, :stimulus_action, :icon
  end
end
# rubocop:enable Metrics/ParameterLists

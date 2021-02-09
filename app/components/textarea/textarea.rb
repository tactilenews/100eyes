# frozen_string_literal: true

module Textarea
  class Textarea < ApplicationComponent
    def initialize(id: nil, value: nil, **)
      super

      @id = id
      @value = value
    end

    def call
      tag.textarea(value, **attrs)
    end

    private

    attr_reader :id, :value

    def attrs
      super.defaults(
        id: id,
        name: id,
        data: {
          controller: 'textarea',
          action: 'input->textarea#resize'
        }
      )
    end
  end
end

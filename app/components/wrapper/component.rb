# frozen_string_literal: true

module Wrapper
  class Component < ApplicationComponent
    def call
      tag.div(content, **attrs)
    end
  end
end

# frozen_string_literal: true

module Box
  class Component < ApplicationComponent
    def call
      tag.div(content, **attrs)
    end
  end
end

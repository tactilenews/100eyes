# frozen_string_literal: true

module Flex
  class Component < ApplicationComponent
    def call
      tag.div(content, class: class_attr)
    end
  end
end

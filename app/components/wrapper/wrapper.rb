# frozen_string_literal: true

module Wrapper
  class Wrapper < ApplicationComponent
    def call
      tag.div(@content, class: class_attr)
    end
  end
end

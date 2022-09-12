# frozen_string_literal: true

module Toolbar
  class Toolbar < ApplicationComponent
    def call
      tag.div(content, class: class_attr, role: 'toolbar', 'aria-label': t('.toolbar'), tabindex: '0', **attrs)
    end
  end
end

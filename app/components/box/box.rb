# frozen_string_literal: true

module Box
  class Box < ApplicationComponent
    def call
      tag.div(@content, class: class_names)
    end
  end
end

# frozen_string_literal: true

module ImageInput
  class ImageInput < ApplicationComponent
    def call
      component('input', attrs.except(:value).merge(type: :file))
    end
  end
end

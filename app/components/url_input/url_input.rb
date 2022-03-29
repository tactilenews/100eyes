# frozen_string_literal: true

module UrlInput
  class UrlInput < ApplicationComponent
    def call
      component('input', type: :url, **attrs)
    end
  end
end

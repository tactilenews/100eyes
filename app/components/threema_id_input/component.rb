# frozen_string_literal: true

module ThreemaIdInput
  class Component < ApplicationComponent
    def call
      c('input', pattern: '[A-Za-z0-9]{8}', **attrs)
    end
  end
end

# frozen_string_literal: true

module Heading
  class Heading < ApplicationComponent
    SIZE_MAPPINGS = {
      h1: :alpha,
      h2: :beta,
      h3: :gamma
    }.freeze

    def initialize(tag: :h1, **)
      super

      @tag = tag
    end

    def call
      content_tag(tag, content, class: class_names)
    end

    private

    def styles
      @styles.presence || [size]
    end

    def size
      SIZE_MAPPINGS.fetch(tag, :alpha)
    end

    def tag
      @tag.to_sym
    end
  end
end

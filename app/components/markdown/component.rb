# frozen_string_literal: true

module Markdown
  class Component < ApplicationComponent
    def initialize(raw:, **)
      super

      @raw = raw
    end

    private

    attr_reader :raw

    def rendered
      doc = Kramdown::Document.new(raw, smart_quotes: %w[sbquo lsquo bdquo ldquo])

      # rubocop:disable Rails/OutputSafety
      doc.to_html.html_safe
      # rubocop:enable Rails/OutputSafety
    end
  end
end

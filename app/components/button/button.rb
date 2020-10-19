# frozen_string_literal: true

module Button
  class Button < ApplicationComponent
    def initialize(label: nil, type: nil, link: nil, stimulus_target: nil, **)
      super

      @styles = [:primary] if @styles.empty?

      @label = label
      @type = type
      @link = link
      @stimulus_target = stimulus_target
    end

    def call
      content_tag(
        tag,
        content,
        class: class_names,
        type: type,
        href: link,
        data: {
          target: stimulus_target
        }
      )
    end

    private

    attr_reader :label, :type, :link, :stimulus_target

    def tag
      return :a if link

      :button
    end

    def content
      label || @content
    end
  end
end

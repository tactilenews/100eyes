module Button
  class Button < ViewComponent::Base
    def initialize(label: nil, style: 'primary', type: nil)
      @label = label
      @style = style
      @type = type
    end

    def call
      content_tag(:button, content, class: class_names, type: type)
    end

    private

    def class_names
      ['c-button', "c-button--#{style}"]
    end

    def content
      return label || @content
    end

    attr_reader :label, :style, :type
  end
end

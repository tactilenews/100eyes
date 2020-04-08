module Button
  class Button < ViewComponent::Base
    def initialize(style: 'primary', type: nil)
      @style = style
      @type = type
    end

    def call
      content_tag(:button, content, class: class_names, type: type)
    end

    def class_names
      ['c-button', "c-button--#{style}"]
    end

    private

    attr_reader :content, :style, :type
  end
end

module Button
  class Button < ViewComponent::Base
    def initialize(title: nil, style: 'primary')
      @style = style
    end

    def call
      content_tag(:button, @content, class: class_names)
    end

    def class_names
      ['c-button', "c-button--#{@style}"]
    end
  end
end

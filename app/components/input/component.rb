# frozen_string_literal: true

module Input
  class Component < ApplicationComponent
    def initialize(id: nil, icon: nil, **)
      super

      @id = id
      @icon = icon

      styles << :icon if icon
    end

    def call
      tag.div(**attrs.slice(:class)) do
        concat icon_tag
        concat input_tag
      end
    end

    private

    attr_reader :icon, :id

    def input_tag
      tag.input(nil, **attrs.defaults(type: :text, id: id, name: id).except(:class))
    end

    def icon_tag
      return c('icon', icon: icon, style: :inline) if icon
    end
  end
end

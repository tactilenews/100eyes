# frozen_string_literal: true

module SidebarItem
  class Component < ApplicationComponent
    def initialize(active: false, **)
      super

      @active = active
    end

    private

    def styles
      return super << :active if active?

      super
    end

    def attrs
      return super.merge(data: { two_column_layout_target: 'activeItem' }) if active?

      super
    end

    def active?
      @active
    end
  end
end

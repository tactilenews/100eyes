# frozen_string_literal: true

module SidebarItem
  class SidebarItem < ApplicationComponent
    def initialize(active: false, **)
      super

      @active = active
      @styles << :active if active
    end

    private

    attr_reader :active
  end
end

# frozen_string_literal: true

module PageHeader
  class PageHeader < ApplicationComponent
    renders_one :tab_bar

    private

    def styles
      return super + [:tab_Bar] if tab_bar

      super
    end
  end
end
